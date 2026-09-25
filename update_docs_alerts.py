import re

html_path = r'c:\Users\willy\OneDrive\Área de Trabalho\documentacao-monitor-diabetes\index.html'

with open(html_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update Visão Geral to include the warning about `projeto_cronicos_v2`
warning_html = """
                    <!-- Bloco: Alerta de Atualização de Dados -->
                    <div class="bg-red-50 border-l-4 border-red-500 p-4 rounded-r-lg mb-6">
                        <h4 class="font-semibold text-red-800 flex items-center mb-2">
                            <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path></svg>
                            ATENÇÃO: Fonte de Dados Primária
                        </h4>
                        <p class="text-sm text-red-900 leading-relaxed">
                            A tabela atual (<strong class="font-mono">diabetes_final</strong>) consome dados de <strong class="font-mono">rj-sms-sandbox.sub_pav_us.projeto_cronicos_v2</strong>. É <strong>CRÍTICO</strong> verificar se existe uma pipeline automatizada atualizando a <code>projeto_cronicos_v2</code> periodicamente. Anteriormente, o monitor era alimentado pela <code>MM_2026_novos_cadastros</code>, que deixou de ser atualizada em maio de 2026. Sem atualização consistente da fonte primária (Vitacare e Científica Lab), os indicadores deste dashboard estarão defasados.
                        </p>
                    </div>
"""

# Insert warning after "Construção da Tabela de Dados" block
content = re.sub(
    r'(<div class="bg-blue-50 border-l-4 border-blue-500.*?</p>\s*</div>)',
    r'\1\n' + warning_html,
    content,
    flags=re.DOTALL
)

# 2. Update Dictionary for `prioridade_dm` and `prioridade_pre_dm` to include full explanation of levels
dm_priority_detail = """Valores: 
- <strong>Crítico</strong>: Com lacuna (alta gravidade) e Sem acompanhamento adequado.
- <strong>Alto</strong>: Com lacuna, mas Com acompanhamento (paciente já está no radar).
- <strong>Moderado</strong>: Sem lacuna, porém Sem acompanhamento longo (baixo risco clínico imediato, mas risco de perda de vínculo).
- <strong>Baixo</strong>: Sem lacuna e Com acompanhamento (paciente estabilizado e engajado).

*O que é considerado LACUNA:* Ausência de CID, HAS descontrolada, Sem HbA1c recente, HbA1c descontrolada, Ausência de exame dos pés, ou IRC sem medicação protetora.
*O que é considerado ACOMPANHAMENTO:* Retorno e exames em <90 dias para pacientes descontrolados, ou <180 dias para estabilizados."""

content = re.sub(
    r'(field:\s*"prioridade_dm",\s*type:\s*"STRING",\s*desc:\s*"Categorização de Risco/Prioridade para Busca Ativa.",\s*detail:\s*)"Valores: \'Crítico\', \'Alto\', \'Moderado\', \'Baixo\'\.\.\."',
    rf'\1"{dm_priority_detail}"',
    content
)

predm_priority_detail = """Valores: 
- <strong>Crítico</strong>: Pré-DM sem glicemia recente (>180d) E sem acompanhamento.
- <strong>Alto</strong>: Sem glicemia (>180d) mas mantém acompanhamento geral.
- <strong>Moderado</strong>: Monitoramento glicêmico em dia, mas sem consulta médica recente (>180d).
- <strong>Baixo</strong>: Status glicêmico e consulta ambos dentro da janela de 180 dias."""

content = re.sub(
    r'(field:\s*"prioridade_pre_dm",\s*type:\s*"STRING",\s*desc:\s*"Priorização para agenda preventiva.",\s*detail:\s*)"Categorização de risco para pacientes pré-diabéticos \(Crítico/Alto/Moderado/Baixo\)(.*?)"',
    rf'\1"{predm_priority_detail}"',
    content
)


# 3. Update 'perfil_cuidado_365d' detail to warn about missing source code
cuidado_detail = """Valores esperados: Compartilhado, Médico centrado, Enfermagem centrado, Sem consultas, e Indefinido.
<strong>NOTA:</strong> A documentação precisa dos critérios exatos (código fonte da tabela <code>projeto_cronicos_v2</code>) para explicar como "Indefinido" e as demais categorias são calculadas (provavelmente cruza CADS médico vs enfermagem). Aguardando fornecimento do script raiz."""

content = re.sub(
    r'(field:\s*"perfil_cuidado_365d",\s*type:\s*"STRING",\s*desc:\s*"Classificação baseada no benchmark de consultas.",\s*detail:\s*").*?"',
    rf'\1{cuidado_detail}"',
    content
)


with open(html_path, 'w', encoding='utf-8') as f:
    f.write(content)
