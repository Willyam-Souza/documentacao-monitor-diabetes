import re

html_path = r'c:\Users\willy\OneDrive\Área de Trabalho\documentacao-monitor-diabetes\index.html'
sql_path = r'c:\Users\willy\OneDrive\Área de Trabalho\documentacao-monitor-diabetes\query.sql'

with open(html_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update text description
content = re.sub(
    r'A tabela que alimenta este monitor — <strong class="font-mono">MM_2026_novos_cadastros_stopp_start</strong> — é construída a partir de outra tabela base do projeto de Multimorbidade \(<strong class="font-mono">MM_2026_novos_cadastros</strong>\), integrando também regras clínicas do protocolo <strong>STOPP/START</strong> e dados de exames laboratoriais da rede municipal.',
    'A tabela que alimenta este monitor — <strong class="font-mono">diabetes_final</strong> — é construída a partir da tabela base do projeto de crônicos (<strong class="font-mono">projeto_cronicos_v2</strong>). Além disso, é gerada uma tabela auxiliar <strong class="font-mono">diabetes_treemap_agravos_eq</strong> para agregação estruturada de agravos.',
    content
)

# 2. Change file name text
content = content.replace('MM_2026_novos_cadastros_stopp_start.sql', 'diabetes_final_e_agravos.sql')

# 3. Replace SQL Code Block
with open(sql_path, 'r', encoding='utf-8') as f:
    sql_text = f.read()

# Use html escaping for safe < > & in sql if necessary, but typically simple strings don't need much unless they contain tags
sql_text = sql_text.replace('<', '&lt;').replace('>', '&gt;')

content = re.sub(
    r'<pre class="p-6 overflow-x-auto text-sm text-slate-300 font-mono leading-relaxed" id="sql-code">.*?</pre>',
    f'<pre class="p-6 overflow-x-auto text-sm text-slate-300 font-mono leading-relaxed" id="sql-code">{sql_text}</pre>',
    content,
    flags=re.DOTALL
)

# 4. Update prioridade_dm and prioridade_pre_dm description
content = re.sub(
    r'(field:\s*"prioridade_dm",\s*type:\s*"STRING",\s*desc:\s*"Categorização de Risco/Prioridade para Busca Ativa.",\s*detail:\s*")Valores:\s*\'Alta\',\s*\'Média\',\s*\'Baixa\'',
    r'\1Valores: \'Crítico\', \'Alto\', \'Moderado\', \'Baixo\'',
    content
)

content = re.sub(
    r'(field:\s*"prioridade_pre_dm",\s*type:\s*"STRING",\s*desc:\s*"Priorização para agenda preventiva.",\s*detail:\s*"Categorização de risco para pacientes pré-diabéticos \()Alta/Média/Baixa(\))',
    r'\1Crítico/Alto/Moderado/Baixo\2',
    content
)

content = re.sub(
    r'(field:\s*"nivel_alerta_geral",\s*type:\s*"STRING",\s*desc:\s*"Semaforização unificada baseada em Charlson, Multimorbidade e Lacunas.",\s*detail:\s*".*?Valores:\s*)Vermelho,\s*Amarelo,\s*Verde\.',
    r"\1'Crítico', 'Alto', 'Moderado', 'Baixo'.",
    content
)

# 5. Insert new flags to dictionaryData
new_flags = """
            {
                field: "sem_exame_ultimo_ano_pre_dm",
                type: "BOOLEAN",
                desc: "Ausência de HbA1c e Glicemia no último ano.",
                detail: "Verifica se não houve dosagem de HbA1c ou glicose de jejum nos últimos 365 dias para pacientes pré-diabéticos."
            },
            {
                field: "sem_acompanhamento_pre_dm_flag",
                type: "BOOLEAN",
                desc: "Falta de acompanhamento (flag literal).",
                detail: "Baseado na coluna regularidade_acompanhamento, indica deficiência de acompanhamento longitudinal no Pré-DM."
            },
"""

# Find where to inject (e.g. before flag_pre_dm_sem_monitoramento_glicemico_180d)
content = content.replace(
    'field: "flag_pre_dm_sem_monitoramento_glicemico_180d",',
    new_flags.lstrip() + '            {\n                field: "flag_pre_dm_sem_monitoramento_glicemico_180d",'
)


with open(html_path, 'w', encoding='utf-8') as f:
    f.write(content)
