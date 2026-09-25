const fs = require('fs');
let html = fs.readFileSync('template.html', 'utf8');

// 1. Update the warning block in Visão Geral
const warning_html = `
        <div class="mm-callout mm-callout--warn">
          <div class="mm-callout__icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
          </div>
          <div>
            <h4>ATENÇÃO: Fonte de Dados Primária</h4>
            <p>
              A tabela atual (<code>diabetes_final</code>) consome dados de <code>rj-sms-sandbox.sub_pav_us.projeto_cronicos_v2</code>. É <strong>CRÍTICO</strong> verificar se existe uma pipeline automatizada atualizando a <code>projeto_cronicos_v2</code> periodicamente. 
              Anteriormente, o monitor era alimentado pela <code>MM_2026_novos_cadastros</code>, que deixou de ser atualizada em maio de 2026. Sem atualização consistente da fonte primária, os indicadores deste dashboard estarão defasados.
            </p>
          </div>
        </div>
`;

// Insert after the second callout
html = html.replace(/(<div class="mm-callout mm-callout--note">.*?<\/div>\s*<\/div>)/s, '$1\n' + warning_html);

// 2. Update dictionary items logic
const dm_priority_detail = `Valores: 
- <strong>Crítico</strong>: Com lacuna (alta gravidade) e Sem acompanhamento adequado.
- <strong>Alto</strong>: Com lacuna, mas Com acompanhamento (paciente já está no radar).
- <strong>Moderado</strong>: Sem lacuna, porém Sem acompanhamento longo (baixo risco clínico imediato, mas risco de perda de vínculo).
- <strong>Baixo</strong>: Sem lacuna e Com acompanhamento (paciente estabilizado e engajado).

*O que é considerado LACUNA:* Ausência de CID, HAS descontrolada, Sem HbA1c recente, HbA1c descontrolada, Ausência de exame dos pés, ou IRC sem medicação protetora.
*O que é considerado ACOMPANHAMENTO:* Retorno e exames em <90 dias para pacientes descontrolados, ou <180 dias para estabilizados.`;

html = html.replace(/(field:\s*"prioridade_dm",\s*type:\s*"STRING",\s*desc:\s*"Categorização de Risco.*?detail:\s*)"[^"]*?"/s, `$1"${dm_priority_detail.replace(/\n/g, '\\n')}"`);

const predm_priority_detail = `Valores: 
- <strong>Crítico</strong>: Pré-DM sem glicemia recente (>180d) E sem acompanhamento.
- <strong>Alto</strong>: Sem glicemia (>180d) mas mantém acompanhamento geral.
- <strong>Moderado</strong>: Monitoramento glicêmico em dia, mas sem consulta médica recente (>180d).
- <strong>Baixo</strong>: Status glicêmico e consulta ambos dentro da janela de 180 dias.`;

html = html.replace(/(field:\s*"prioridade_pre_dm",\s*type:\s*"STRING",\s*desc:\s*".*?",\s*detail:\s*)"[^"]*?"/s, `$1"${predm_priority_detail.replace(/\n/g, '\\n')}"`);

const cuidado_detail = `Valores esperados: Compartilhado, Médico centrado, Enfermagem centrado, Sem consultas, e Indefinido.
<strong>NOTA:</strong> A documentação precisa dos critérios exatos (código fonte da tabela <code>projeto_cronicos_v2</code>) para explicar como "Indefinido" e as demais categorias são calculadas (provavelmente cruza CADS médico vs enfermagem). Aguardando fornecimento do script raiz.`;

html = html.replace(/(field:\s*"perfil_cuidado_365d",\s*type:\s*"STRING",\s*desc:\s*".*?",\s*detail:\s*)"[^"]*?"/s, `$1"${cuidado_detail.replace(/\n/g, '\\n')}"`);

fs.writeFileSync('index.html', html);
console.log("Successfully updated dictionary and applied layout.");
