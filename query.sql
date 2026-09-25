-- =====================================================================================
-- TABELA ENXUTA PARA DASHBOARD DE DIABETES / PRÉ-DIABETES
-- Fonte: `rj-sms-sandbox.sub_pav_us.MM_2026_novos_cadastros`
-- Destino: `rj-sms-sandbox.sub_pav_pet_saude.diabetes_final`
--
-- LÓGICA:
--   DM
--     - com_lacuna_dm            = lacunas clínicas prioritárias
--     - com_acompanhamento_dm    = fluxo/periodicidade adequada
--
--   PRÉ-DM
--     - com_lacuna_pre_dm            = ausência de monitoramento glicêmico
--     - sem_acompanhamento_pre_dm    = fluxo/periodicidade inadequada
--
--   PRIORIDADE
--     - Crítico   = com lacuna + sem acompanhamento
--     - Alto      = com lacuna + com acompanhamento
--     - Moderado  = sem lacuna + sem acompanhamento
--     - Baixo     = sem lacuna + com acompanhamento
--
-- OBS:
--   - mantém nome e data de nascimento para busca no sistema
--   - CPF não é exposto; é gerado hash
-- =====================================================================================

CREATE OR REPLACE TABLE `rj-sms-sandbox.sub_pav_pet_saude.diabetes_final` AS

WITH base_filtrada AS (
  SELECT
    -- Identificação / demografia
    cpf,
    nome,
    genero,
    idade,
    data_nascimento,
    raca,

    -- Vínculo APS / equipe
    id_ine_cadastro,
    nome_esf_cadastro,
    id_cnes_cadastro,
    nome_clinica_cadastro,
    nome_medico_esf_cadastro,
    nome_enfermeiro_esf_cadastro,
    area_programatica_cadastro,

    -- Evidência de DM / pré-DM
    pre_DM,
    DM,
    dm_por_cid,
    dm_por_exames,
    dm_por_progressao_pre_dm,
    dm_por_medicamento_forte,
    DM_sem_CID,
    provavel_dm1,

    -- Controle glicêmico
    hba1c_atual,
    data_hba1c_atual,
    hba1c_anterior,
    data_hba1c_anterior,
    dias_entre_hba1c,
    dias_desde_ultima_hba1c,
    tendencia_hba1c,
    meta_hba1c,
    meta_hba1c_lacunas,
    status_controle_glicemico,
    DM_controlado,
    DM_piorando,
    DM_melhorando,
    dias_dm_controlado,
    dias_dm_descontrolado,
    pct_dias_dm_controlado,
    dias_dm_controlado_365d,
    dias_dm_descontrolado_365d,
    pct_dias_dm_controlado_365d,

    glicemia,
    data_glicemia,
    dias_desde_ultima_glicemia,
    ultimas_tres_glicemias,
    ultimas_tres_A1C,

    -- HAS / pressão arterial
    HAS,
    has_por_cid,
    has_por_medida_critica,
    has_por_medidas_repetidas,
    has_por_medicamento,
    HAS_sem_CID,

    pressao_sistolica,
    pressao_diastolica,
    data_ultima_pa,
    dias_desde_ultima_pa,
    meta_pas,
    meta_pad,
    status_controle_pressorio,
    tendencia_pa,
    ultimas_tres_PA,

    -- Antropometria / obesidade
    peso,
    data_peso,
    altura,
    data_altura,
    IMC,
    obesidade_por_IMC,
    obesidade,
    obesidade_consolidada,

    -- Perfil lipídico / risco cardiovascular
    colesterol_total,
    data_colesterol,
    hdl,
    data_hdl,
    ldl,
    data_ldl,
    triglicerides,
    classificacao_colesterol_total,
    classificacao_hdl,
    classificacao_ldl,
    classificacao_triglicerides,

    dislipidemia,
    dislipidemia_por_CID,
    dislipidemia_por_CT,
    dislipidemia_por_LDL,
    dislipidemia_por_HDL_baixo,
    dislipidemia_por_TG,

    risco_cardiovascular,

    -- Rim / doença renal
    creatinina,
    data_creatinina,
    egfr,
    ckd_stage,
    IRC,
    necessita_funcao_renal,

    lacuna_creatinina_HAS_DM,
    lacuna_IRC_sem_SGLT2,
    lacuna_IRC_sem_iECA_ou_BRA,
    data_ultima_SGLT2,
    dias_desde_ultima_SGLT2,
    lacuna_DM_complicado_sem_SGLT2,

    -- Pé diabético
    teve_exame_pe_365d,
    teve_exame_pe_180d,
    data_ultimo_exame_pe,
    dias_desde_ultimo_exame_pe,
    lacuna_DM_sem_exame_pe_365d,
    lacuna_DM_sem_exame_pe_180d,
    lacuna_DM_nunca_teve_exame_pe,

    -- Olhos
    olhos,

    -- Comorbidades cardiovasculares + hábitos
    CI,
    ICC,
    stroke,
    vascular_periferica,
    arritmia,
    valvular,
    alcool,
    tabaco,

    -- Lacunas já existentes
    lacuna_DM_sem_HbA1c_recente,
    lacuna_DM_descontrolado,
    lacuna_DM_hba1c_nao_solicitado,
    lacuna_DM_microalbuminuria_nao_solicitado,
    lacuna_DM_HAS_PA_descontrolada,
    lacuna_IMC_HAS_DM,
    lacuna_colesterol_HAS_DM,
    lacuna_eas_HAS_DM,
    lacuna_ecg_HAS_DM,
    lacuna_PA_hipertenso_180d,
    lacuna_rastreio_DM_hipertenso,
    lacuna_rastreio_DM_45mais,
    lacuna_HAS_descontrolado_menor80,
    lacuna_HAS_descontrolado_80mais,

    -- Seguimento / longitudinalidade
    consultas_total_historico,
    consultas_medicas_historico,
    consultas_365d,
    consultas_medicas_365d,
    data_primeira_consulta,
    data_ultima_consulta,
    dias_desde_ultima_consulta,
    perfil_cuidado_365d,
    regularidade_acompanhamento,
    baixa_longitudinalidade,

    -- Tratamento crônico / polifarmácia
    total_medicamentos_cronicos,
    nucleo_cronico_atual,
    data_ultima_prescricao_cronica,
    dias_desde_ultima_prescricao_cronica,
    polifarmacia,
    hiperpolifarmacia

  FROM `rj-sms-sandbox.sub_pav_us.projeto_cronicos_v2`
  WHERE
    pre_DM IS NOT NULL
    OR DM IS NOT NULL
    OR dm_por_cid IS NOT NULL
    OR dm_por_exames IS NOT NULL
    OR dm_por_progressao_pre_dm IS NOT NULL
    OR dm_por_medicamento_forte IS NOT NULL
    OR IFNULL(DM_sem_CID, FALSE) = TRUE
),

cadastro_npront AS (
  SELECT
    SAFE_CAST(cpf AS STRING) AS cpf,
    SAFE_CAST(id_cnes AS STRING) AS id_cnes,
    ANY_VALUE(npront) AS npront
  FROM `rj-sms.brutos_prontuario_vitacare_historico.cadastro`
  GROUP BY 1, 2
),

base_com_regras AS (
  SELECT
    -- Identificação
    TO_HEX(SHA256(CAST(cpf AS STRING))) AS id_paciente,
    cpf,
    nome,
    genero,
    idade,
    data_nascimento,
    raca,

    -- Equipe
    id_ine_cadastro,
    nome_esf_cadastro,
    id_cnes_cadastro,
    nome_clinica_cadastro,
    nome_medico_esf_cadastro,
    nome_enfermeiro_esf_cadastro,
    area_programatica_cadastro,

    -- Evidência de DM / pré-DM
    pre_DM,
    DM,
    dm_por_cid,
    dm_por_exames,
    dm_por_progressao_pre_dm,
    dm_por_medicamento_forte,
    DM_sem_CID,
    provavel_dm1,

    -- Controle glicêmico
    hba1c_atual,
    data_hba1c_atual,
    hba1c_anterior,
    data_hba1c_anterior,
    dias_entre_hba1c,
    dias_desde_ultima_hba1c,
    tendencia_hba1c,
    meta_hba1c,
    meta_hba1c_lacunas,
    status_controle_glicemico,
    DM_controlado,
    DM_piorando,
    DM_melhorando,
    dias_dm_controlado,
    dias_dm_descontrolado,
    pct_dias_dm_controlado,
    dias_dm_controlado_365d,
    dias_dm_descontrolado_365d,
    pct_dias_dm_controlado_365d,
    glicemia,
    data_glicemia,
    dias_desde_ultima_glicemia,
    ultimas_tres_glicemias,
    ultimas_tres_A1C,

    -- HAS / PA
    HAS,
    has_por_cid,
    has_por_medida_critica,
    has_por_medidas_repetidas,
    has_por_medicamento,
    HAS_sem_CID,
    pressao_sistolica,
    pressao_diastolica,
    data_ultima_pa,
    dias_desde_ultima_pa,
    meta_pas,
    meta_pad,
    status_controle_pressorio,
    tendencia_pa,
    ultimas_tres_PA,

    -- IMC / obesidade
    peso,
    data_peso,
    altura,
    data_altura,
    IMC,
    obesidade_por_IMC,
    obesidade,
    obesidade_consolidada,

    -- Lipídios / risco cardiovascular
    colesterol_total,
    data_colesterol,
    hdl,
    data_hdl,
    ldl,
    data_ldl,
    triglicerides,
    classificacao_colesterol_total,
    classificacao_hdl,
    classificacao_ldl,
    classificacao_triglicerides,
    dislipidemia,
    dislipidemia_por_CID,
    dislipidemia_por_CT,
    dislipidemia_por_LDL,
    dislipidemia_por_HDL_baixo,
    dislipidemia_por_TG,
    risco_cardiovascular,

    -- Rim
    creatinina,
    data_creatinina,
    egfr,
    ckd_stage,
    IRC,
    necessita_funcao_renal,
    lacuna_creatinina_HAS_DM,
    lacuna_IRC_sem_SGLT2,
    lacuna_IRC_sem_iECA_ou_BRA,
    data_ultima_SGLT2,
    dias_desde_ultima_SGLT2,
    lacuna_DM_complicado_sem_SGLT2,

    -- Pé diabético
    teve_exame_pe_365d,
    teve_exame_pe_180d,
    data_ultimo_exame_pe,
    dias_desde_ultimo_exame_pe,
    lacuna_DM_sem_exame_pe_365d,
    lacuna_DM_sem_exame_pe_180d,
    lacuna_DM_nunca_teve_exame_pe,

    -- Olhos
    olhos,

    -- Comorbidades + hábitos
    CI,
    ICC,
    stroke,
    vascular_periferica,
    arritmia,
    valvular,
    alcool IS NOT NULL AS tem_alcool,
    tabaco IS NOT NULL AS tem_tabagismo,

    -- Lacunas originais
    lacuna_DM_sem_HbA1c_recente,
    lacuna_DM_descontrolado,
    lacuna_DM_hba1c_nao_solicitado,
    lacuna_DM_microalbuminuria_nao_solicitado,
    lacuna_DM_HAS_PA_descontrolada,
    lacuna_IMC_HAS_DM,
    lacuna_colesterol_HAS_DM,
    lacuna_eas_HAS_DM,
    lacuna_ecg_HAS_DM,
    lacuna_PA_hipertenso_180d,
    lacuna_rastreio_DM_hipertenso,
    lacuna_rastreio_DM_45mais,
    lacuna_HAS_descontrolado_menor80,
    lacuna_HAS_descontrolado_80mais,

    -- Seguimento / longitudinalidade
    consultas_total_historico,
    consultas_medicas_historico,
    consultas_365d,
    consultas_medicas_365d,
    data_primeira_consulta,
    data_ultima_consulta,
    dias_desde_ultima_consulta,
    perfil_cuidado_365d,
    regularidade_acompanhamento,
    baixa_longitudinalidade,

    -- Tratamento crônico / polifarmácia
    total_medicamentos_cronicos,
    nucleo_cronico_atual,
    data_ultima_prescricao_cronica,
    dias_desde_ultima_prescricao_cronica,
    polifarmacia,
    hiperpolifarmacia,

    -- =========================================================
    -- DM: lacunas clínicas prioritárias
    -- =========================================================
    CASE
      WHEN
        IFNULL(DM_sem_CID, FALSE)
        OR IFNULL(lacuna_DM_descontrolado, FALSE)
        OR IFNULL(lacuna_DM_sem_HbA1c_recente, FALSE)
        OR IFNULL(lacuna_DM_nunca_teve_exame_pe, FALSE)
        OR IFNULL(lacuna_DM_sem_exame_pe_365d, FALSE)
        OR IFNULL(lacuna_IRC_sem_SGLT2, FALSE)
        OR IFNULL(lacuna_IRC_sem_iECA_ou_BRA, FALSE)
      THEN 'Sim'
      ELSE 'Não'
    END AS com_lacuna_dm,

    -- =========================================================
    -- DM: acompanhamento adequado
    -- Descontrolado/piorando = 90 dias
    -- Estável = 180 dias
    -- =========================================================
    CASE
      WHEN
        DM IS NOT NULL
        AND (
          (
            (IFNULL(DM_piorando, FALSE) = TRUE OR IFNULL(lacuna_DM_descontrolado, FALSE) = TRUE)
            AND IFNULL(dias_desde_ultima_consulta, 999999) <= 90
            AND IFNULL(dias_desde_ultima_hba1c, 999999) <= 90
          )
          OR
          (
            (IFNULL(DM_piorando, FALSE) = FALSE AND IFNULL(lacuna_DM_descontrolado, FALSE) = FALSE)
            AND IFNULL(dias_desde_ultima_consulta, 999999) <= 180
            AND IFNULL(dias_desde_ultima_hba1c, 999999) <= 180
          )
        )
      THEN 'Sim'
      ELSE 'Não'
    END AS com_acompanhamento_dm,

    -- =========================================================
    -- PRÉ-DM: lacuna conservadora
    -- =========================================================
    CASE
      WHEN
        pre_DM IS NOT NULL
        AND DM IS NULL
        AND IFNULL(dias_desde_ultima_hba1c, 999999) > 180
        AND IFNULL(dias_desde_ultima_glicemia, 999999) > 180
      THEN 'Sim'
      ELSE 'Não'
    END AS com_lacuna_pre_dm,

    -- =========================================================
    -- PRÉ-DM: sem acompanhamento
    -- =========================================================
    CASE
      WHEN
        pre_DM IS NOT NULL
        AND DM IS NULL
        AND (
          IFNULL(dias_desde_ultima_consulta, 999999) > 180
          OR (
            IFNULL(dias_desde_ultima_hba1c, 999999) > 180
            AND IFNULL(dias_desde_ultima_glicemia, 999999) > 180
          )
          OR IFNULL(baixa_longitudinalidade, FALSE) = TRUE
        )
      THEN 'Sim'
      ELSE 'Não'
    END AS sem_acompanhamento_pre_dm

  FROM base_filtrada
)

SELECT
  t.*,
  c.npront,

  -- =========================================================
  -- DM: motivo principal
  -- =========================================================
  CASE
    WHEN IFNULL(t.lacuna_DM_descontrolado, FALSE) THEN 'DM descontrolado'
    WHEN IFNULL(t.lacuna_DM_sem_HbA1c_recente, FALSE) THEN 'Sem HbA1c recente'
    WHEN IFNULL(t.lacuna_DM_nunca_teve_exame_pe, FALSE) THEN 'Nunca teve exame de pe'
    WHEN IFNULL(t.lacuna_DM_sem_exame_pe_365d, FALSE) THEN 'Sem exame de pe >365d'
    WHEN IFNULL(t.lacuna_IRC_sem_SGLT2, FALSE) THEN 'IRC sem SGLT2'
    WHEN IFNULL(t.lacuna_IRC_sem_iECA_ou_BRA, FALSE) THEN 'IRC sem IECA ou BRA'
    WHEN IFNULL(t.DM_sem_CID, FALSE) THEN 'DM sem CID'
    ELSE NULL
  END AS motivo_alerta_principal,

  -- =========================================================
  -- DM: resumo
  -- =========================================================
  ARRAY_TO_STRING(
    ARRAY(
      SELECT item
      FROM UNNEST([
        IF(IFNULL(t.DM_sem_CID, FALSE), 'DM sem CID', NULL),
        IF(IFNULL(t.lacuna_DM_descontrolado, FALSE), 'DM descontrolado', NULL),
        IF(IFNULL(t.lacuna_DM_sem_HbA1c_recente, FALSE), 'Sem HbA1c recente', NULL),
        IF(IFNULL(t.lacuna_DM_nunca_teve_exame_pe, FALSE), 'Nunca teve exame de pe', NULL),
        IF(IFNULL(t.lacuna_DM_sem_exame_pe_365d, FALSE), 'Sem exame de pe >365d', NULL),
        IF(IFNULL(t.lacuna_IRC_sem_SGLT2, FALSE), 'IRC sem SGLT2', NULL),
        IF(IFNULL(t.lacuna_IRC_sem_iECA_ou_BRA, FALSE), 'IRC sem IECA ou BRA', NULL)
      ]) AS item
      WHERE item IS NOT NULL
    ),
    '; '
  ) AS lacunas_resumo,

  -- =========================================================
  -- NOVOS CAMPOS DE AUDITORIA - DM
  -- =========================================================
  CASE
    WHEN DM IS NOT NULL AND IFNULL(DM_sem_CID, FALSE) THEN TRUE
    ELSE FALSE
  END AS flag_dm_sem_cid,

  CASE
    WHEN DM IS NOT NULL AND IFNULL(lacuna_DM_descontrolado, FALSE) THEN TRUE
    ELSE FALSE
  END AS flag_dm_descontrolado,

  CASE
    WHEN DM IS NOT NULL AND IFNULL(lacuna_DM_sem_HbA1c_recente, FALSE) THEN TRUE
    ELSE FALSE
  END AS flag_dm_sem_hba1c_recente,

  CASE
    WHEN DM IS NOT NULL AND IFNULL(lacuna_DM_nunca_teve_exame_pe, FALSE) THEN TRUE
    ELSE FALSE
  END AS flag_dm_nunca_exame_pe,

  CASE
    WHEN DM IS NOT NULL AND IFNULL(lacuna_DM_sem_exame_pe_365d, FALSE) THEN TRUE
    ELSE FALSE
  END AS flag_dm_sem_exame_pe_365d,

  CASE
    WHEN DM IS NOT NULL AND IFNULL(lacuna_DM_sem_exame_pe_180d, FALSE) THEN TRUE
    ELSE FALSE
  END AS flag_dm_sem_exame_pe_180d,

  CASE
    WHEN DM IS NOT NULL AND IFNULL(lacuna_IRC_sem_SGLT2, FALSE) THEN TRUE
    ELSE FALSE
  END AS flag_dm_irc_sem_sglt2,

  CASE
    WHEN DM IS NOT NULL AND IFNULL(lacuna_IRC_sem_iECA_ou_BRA, FALSE) THEN TRUE
    ELSE FALSE
  END AS flag_dm_irc_sem_ieca_bra,

  CASE
    WHEN DM IS NOT NULL AND IFNULL(lacuna_PA_hipertenso_180d, FALSE) THEN TRUE
    ELSE FALSE
  END AS flag_dm_pa_hipertenso_180d,

  CASE
    WHEN DM IS NOT NULL AND IFNULL(lacuna_HAS_descontrolado_menor80, FALSE) THEN TRUE
    ELSE FALSE
  END AS flag_dm_has_descontrolado_menor80,

  CASE
    WHEN DM IS NOT NULL AND IFNULL(lacuna_HAS_descontrolado_80mais, FALSE) THEN TRUE
    ELSE FALSE
  END AS flag_dm_has_descontrolado_80mais,

  CASE
    WHEN DM IS NOT NULL AND IFNULL(lacuna_rastreio_DM_hipertenso, FALSE) THEN TRUE
    ELSE FALSE
  END AS flag_dm_rastreio_hipertenso,

  CASE
    WHEN DM IS NOT NULL AND IFNULL(lacuna_rastreio_DM_45mais, FALSE) THEN TRUE
    ELSE FALSE
  END AS flag_dm_rastreio_45mais,

  -- =========================================================
  -- NOVOS CAMPOS DE AUDITORIA - ACOMPANHAMENTO DM
  -- =========================================================
  CASE
    WHEN DM IS NOT NULL
         AND (IFNULL(DM_piorando, FALSE) = TRUE OR IFNULL(lacuna_DM_descontrolado, FALSE) = TRUE)
    THEN TRUE
    ELSE FALSE
  END AS flag_dm_precisa_regra_90d,

  CASE
    WHEN DM IS NOT NULL
         AND NOT (IFNULL(DM_piorando, FALSE) = TRUE OR IFNULL(lacuna_DM_descontrolado, FALSE) = TRUE)
    THEN TRUE
    ELSE FALSE
  END AS flag_dm_precisa_regra_180d,

  CASE
    WHEN DM IS NOT NULL AND IFNULL(dias_desde_ultima_consulta, 999999) <= 90 THEN TRUE
    ELSE FALSE
  END AS flag_dm_consulta_90d_ok,

  CASE
    WHEN DM IS NOT NULL AND IFNULL(dias_desde_ultima_consulta, 999999) <= 180 THEN TRUE
    ELSE FALSE
  END AS flag_dm_consulta_180d_ok,

  CASE
    WHEN DM IS NOT NULL AND IFNULL(dias_desde_ultima_hba1c, 999999) <= 90 THEN TRUE
    ELSE FALSE
  END AS flag_dm_hba1c_90d_ok,

  CASE
    WHEN DM IS NOT NULL AND IFNULL(dias_desde_ultima_hba1c, 999999) <= 180 THEN TRUE
    ELSE FALSE
  END AS flag_dm_hba1c_180d_ok,

  CASE
    WHEN DM IS NOT NULL
         AND (IFNULL(DM_piorando, FALSE) = TRUE OR IFNULL(lacuna_DM_descontrolado, FALSE) = TRUE)
         AND IFNULL(dias_desde_ultima_consulta, 999999) <= 90
         AND IFNULL(dias_desde_ultima_hba1c, 999999) <= 90
    THEN TRUE
    ELSE FALSE
  END AS flag_dm_acompanhamento_ok_regra_90d,

  CASE
    WHEN DM IS NOT NULL
         AND NOT (IFNULL(DM_piorando, FALSE) = TRUE OR IFNULL(lacuna_DM_descontrolado, FALSE) = TRUE)
         AND IFNULL(dias_desde_ultima_consulta, 999999) <= 180
         AND IFNULL(dias_desde_ultima_hba1c, 999999) <= 180
    THEN TRUE
    ELSE FALSE
  END AS flag_dm_acompanhamento_ok_regra_180d,

  -- =========================================================
  -- NOVOS CAMPOS DE AUDITORIA - PRÉ-DM
  -- =========================================================
  CASE
    WHEN pre_DM IS NOT NULL
         AND DM IS NULL
         AND IFNULL(dias_desde_ultima_hba1c, 999999) > 180
         AND IFNULL(dias_desde_ultima_glicemia, 999999) > 180
    THEN TRUE
    ELSE FALSE
  END AS flag_pre_dm_sem_monitoramento_glicemico_180d,

  CASE
    WHEN pre_DM IS NOT NULL
         AND DM IS NULL
         AND IFNULL(dias_desde_ultima_consulta, 999999) > 180
    THEN TRUE
    ELSE FALSE
  END AS flag_pre_dm_sem_consulta_180d,

  CASE
    WHEN pre_DM IS NOT NULL
         AND DM IS NULL
         AND (
           (data_hba1c_atual IS NULL OR DATE(data_hba1c_atual) < DATE_SUB(CURRENT_DATE(), INTERVAL 365 DAY))
           AND
           (data_glicemia IS NULL OR DATE(data_glicemia) < DATE_SUB(CURRENT_DATE(), INTERVAL 365 DAY))
         )
    THEN TRUE
    ELSE FALSE
  END AS sem_exame_ultimo_ano_pre_dm,

  CASE
    WHEN pre_DM IS NOT NULL
         AND DM IS NULL
         AND regularidade_acompanhamento = 'sem_acompanhamento'
    THEN TRUE
    ELSE FALSE
  END AS sem_acompanhamento_pre_dm_flag,

  CASE
    WHEN pre_DM IS NOT NULL
         AND DM IS NULL
         AND (IFNULL(obesidade_por_IMC, FALSE) = TRUE OR IFNULL(IMC, 0) >= 30)
         AND IFNULL(dias_desde_ultima_hba1c, 999999) > 180
         AND IFNULL(dias_desde_ultima_glicemia, 999999) > 180
    THEN TRUE
    ELSE FALSE
  END AS flag_pre_dm_obesidade_sem_monitoramento,

  CASE
    WHEN pre_DM IS NOT NULL
         AND DM IS NULL
         AND HAS IS NOT NULL
         AND IFNULL(dias_desde_ultima_hba1c, 999999) > 180
         AND IFNULL(dias_desde_ultima_glicemia, 999999) > 180
    THEN TRUE
    ELSE FALSE
  END AS flag_pre_dm_has_sem_monitoramento,

  CASE
    WHEN pre_DM IS NOT NULL
         AND DM IS NULL
         AND IFNULL(baixa_longitudinalidade, FALSE) = TRUE
    THEN TRUE
    ELSE FALSE
  END AS flag_pre_dm_baixa_longitudinalidade,

  -- =========================================================
  -- NOVOS CAMPOS DE AUDITORIA - ACOMPANHAMENTO PRÉ-DM
  -- =========================================================
  CASE
    WHEN pre_DM IS NOT NULL
         AND DM IS NULL
         AND IFNULL(dias_desde_ultima_consulta, 999999) <= 180
    THEN TRUE
    ELSE FALSE
  END AS flag_pre_dm_consulta_180d_ok,

  CASE
    WHEN pre_DM IS NOT NULL
         AND DM IS NULL
         AND IFNULL(dias_desde_ultima_hba1c, 999999) <= 180
    THEN TRUE
    ELSE FALSE
  END AS flag_pre_dm_hba1c_180d_ok,

  CASE
    WHEN pre_DM IS NOT NULL
         AND DM IS NULL
         AND IFNULL(dias_desde_ultima_glicemia, 999999) <= 180
    THEN TRUE
    ELSE FALSE
  END AS flag_pre_dm_glicemia_180d_ok,

  CASE
    WHEN pre_DM IS NOT NULL
         AND DM IS NULL
         AND (
           IFNULL(dias_desde_ultima_hba1c, 999999) <= 180
           OR IFNULL(dias_desde_ultima_glicemia, 999999) <= 180
         )
    THEN TRUE
    ELSE FALSE
  END AS flag_pre_dm_monitoramento_180d_ok,

  CASE
    WHEN pre_DM IS NOT NULL
         AND DM IS NULL
         AND IFNULL(baixa_longitudinalidade, FALSE) = FALSE
    THEN TRUE
    ELSE FALSE
  END AS flag_pre_dm_sem_baixa_longitudinalidade,

  CASE
    WHEN pre_DM IS NOT NULL
         AND DM IS NULL
         AND IFNULL(dias_desde_ultima_consulta, 999999) <= 180
         AND (
           IFNULL(dias_desde_ultima_hba1c, 999999) <= 180
           OR IFNULL(dias_desde_ultima_glicemia, 999999) <= 180
         )
    THEN TRUE
    ELSE FALSE
  END AS flag_pre_dm_acompanhamento_fluxo_ok,

  -- =========================================================
  -- PRÉ-DM: motivo principal
  -- =========================================================
  CASE
    WHEN
      t.pre_DM IS NOT NULL
      AND t.DM IS NULL
      AND IFNULL(t.dias_desde_ultima_hba1c, 999999) > 180
      AND IFNULL(t.dias_desde_ultima_glicemia, 999999) > 180
    THEN 'Pre-DM sem monitoramento glicemico'
    ELSE NULL
  END AS motivo_alerta_principal_pre_dm,

  -- =========================================================
  -- PRÉ-DM: resumo
  -- =========================================================
  CASE
    WHEN
      t.pre_DM IS NOT NULL
      AND t.DM IS NULL
      AND IFNULL(t.dias_desde_ultima_hba1c, 999999) > 180
      AND IFNULL(t.dias_desde_ultima_glicemia, 999999) > 180
    THEN 'Pre-DM sem monitoramento glicemico'
    ELSE NULL
  END AS lacunas_resumo_pre_dm,

  -- =========================================================
  -- Prioridade DM
  -- =========================================================
  CASE
    WHEN t.com_lacuna_dm = 'Sim' AND t.com_acompanhamento_dm = 'Não' THEN 'Crítico'
    WHEN t.com_lacuna_dm = 'Sim' AND t.com_acompanhamento_dm = 'Sim' THEN 'Alto'
    WHEN t.com_lacuna_dm = 'Não' AND t.com_acompanhamento_dm = 'Não' AND t.DM IS NOT NULL THEN 'Moderado'
    WHEN t.com_lacuna_dm = 'Não' AND t.com_acompanhamento_dm = 'Sim' AND t.DM IS NOT NULL THEN 'Baixo'
    ELSE NULL
  END AS prioridade_dm,

  -- =========================================================
  -- Prioridade pré-DM
  -- =========================================================
  CASE
    WHEN t.com_lacuna_pre_dm = 'Sim' AND t.sem_acompanhamento_pre_dm = 'Sim' THEN 'Crítico'
    WHEN t.com_lacuna_pre_dm = 'Sim' AND t.sem_acompanhamento_pre_dm = 'Não' THEN 'Alto'
    WHEN t.com_lacuna_pre_dm = 'Não' AND t.sem_acompanhamento_pre_dm = 'Sim' AND t.pre_DM IS NOT NULL AND t.DM IS NULL THEN 'Moderado'
    WHEN t.com_lacuna_pre_dm = 'Não' AND t.sem_acompanhamento_pre_dm = 'Não' AND t.pre_DM IS NOT NULL AND t.DM IS NULL THEN 'Baixo'
    ELSE NULL
  END AS prioridade_pre_dm,

  -- =========================================================
  -- Nível de alerta geral
  -- Prioriza DM quando houver DM estabelecido
  -- =========================================================
  CASE
    WHEN t.DM IS NOT NULL THEN
      CASE
        WHEN t.com_lacuna_dm = 'Sim' AND t.com_acompanhamento_dm = 'Não' THEN 'Crítico'
        WHEN t.com_lacuna_dm = 'Sim' AND t.com_acompanhamento_dm = 'Sim' THEN 'Alto'
        WHEN t.com_lacuna_dm = 'Não' AND t.com_acompanhamento_dm = 'Não' THEN 'Moderado'
        WHEN t.com_lacuna_dm = 'Não' AND t.com_acompanhamento_dm = 'Sim' THEN 'Baixo'
        ELSE NULL
      END
    WHEN t.pre_DM IS NOT NULL AND t.DM IS NULL THEN
      CASE
        WHEN t.com_lacuna_pre_dm = 'Sim' AND t.sem_acompanhamento_pre_dm = 'Sim' THEN 'Crítico'
        WHEN t.com_lacuna_pre_dm = 'Sim' AND t.sem_acompanhamento_pre_dm = 'Não' THEN 'Alto'
        WHEN t.com_lacuna_pre_dm = 'Não' AND t.sem_acompanhamento_pre_dm = 'Sim' THEN 'Moderado'
        WHEN t.com_lacuna_pre_dm = 'Não' AND t.sem_acompanhamento_pre_dm = 'Não' THEN 'Baixo'
        ELSE NULL
      END
    ELSE NULL
  END AS nivel_alerta_geral

FROM base_com_regras t
LEFT JOIN cadastro_npront c
  ON SAFE_CAST(t.cpf AS STRING) = c.cpf
 AND SAFE_CAST(t.id_cnes_cadastro AS STRING) = c.id_cnes;


 -- =====================================================================================
-- TABELA AUXILIAR DE AGRAVOS EM PESSOAS COM DIABETES
-- Agregada por AP / unidade / equipe, incluindo pacientes sem equipe ou CPF
-- Fonte: `rj-sms-sandbox.sub_pav_pet_saude.diabetes_final`
-- Destino: `rj-sms-sandbox.sub_pav_pet_saude.diabetes_treemap_agravos_eq`
-- =====================================================================================

CREATE OR REPLACE TABLE `rj-sms-sandbox.sub_pav_pet_saude.diabetes_treemap_agravos_eq` AS

WITH base_dm AS (
  SELECT
    -- Substitui nulos para garantir que todos os pacientes sejam agregados
    COALESCE(area_programatica_cadastro, 'SEM AP') AS area_programatica_cadastro,
    COALESCE(id_cnes_cadastro, 'SEM CNES') AS id_cnes_cadastro,
    COALESCE(nome_clinica_cadastro, 'SEM CLINICA') AS nome_clinica_cadastro,
    COALESCE(id_ine_cadastro, 'SEM INE') AS id_ine_cadastro,
    COALESCE(nome_esf_cadastro, 'SEM EQUIPE') AS nome_esf_cadastro,

    id_paciente,

    HAS,
    obesidade,
    obesidade_por_IMC,
    dislipidemia,
    dislipidemia_por_CID,
    dislipidemia_por_CT,
    dislipidemia_por_LDL,
    dislipidemia_por_HDL_baixo,
    dislipidemia_por_TG,
    IRC,
    CI,
    ICC,
    stroke,
    vascular_periferica,
    arritmia,
    valvular,
    olhos,
    tem_tabagismo,
    tem_alcool

  FROM `rj-sms-sandbox.sub_pav_pet_saude.diabetes_final`
  WHERE DM IS NOT NULL
),

denominador AS (
  SELECT
    area_programatica_cadastro,
    id_cnes_cadastro,
    nome_clinica_cadastro,
    id_ine_cadastro,
    nome_esf_cadastro,
    COUNT(*) AS total_pessoas_dm
  FROM base_dm
  GROUP BY 1,2,3,4,5
),

agravos AS (
  -- HAS
  SELECT
    area_programatica_cadastro,
    id_cnes_cadastro,
    nome_clinica_cadastro,
    id_ine_cadastro,
    nome_esf_cadastro,
    'Metabólico' AS categoria,
    'HAS' AS agravo,
    COUNT(IF(HAS IS NOT NULL, 1, NULL)) AS n_pessoas
  FROM base_dm
  GROUP BY 1,2,3,4,5

  UNION ALL

  -- Obesidade (apenas pela coluna obesidade, sem IMC)
  SELECT
    area_programatica_cadastro,
    id_cnes_cadastro,
    nome_clinica_cadastro,
    id_ine_cadastro,
    nome_esf_cadastro,
    'Metabólico' AS categoria,
    'Obesidade' AS agravo,
    COUNT(IF(obesidade IS NOT NULL, 1, NULL)) AS n_pessoas
  FROM base_dm
  GROUP BY 1,2,3,4,5

  UNION ALL

  -- Dislipidemia
  SELECT
    area_programatica_cadastro,
    id_cnes_cadastro,
    nome_clinica_cadastro,
    id_ine_cadastro,
    nome_esf_cadastro,
    'Metabólico' AS categoria,
    'Dislipidemia' AS agravo,
    COUNT(IF(
      dislipidemia IS NOT NULL
      OR dislipidemia_por_CID IS NOT NULL
      OR IFNULL(dislipidemia_por_CT, FALSE)
      OR IFNULL(dislipidemia_por_LDL, FALSE)
      OR IFNULL(dislipidemia_por_HDL_baixo, FALSE)
      OR IFNULL(dislipidemia_por_TG, FALSE),
      1, NULL
    )) AS n_pessoas
  FROM base_dm
  GROUP BY 1,2,3,4,5

  UNION ALL

  -- IRC
  SELECT
    area_programatica_cadastro,
    id_cnes_cadastro,
    nome_clinica_cadastro,
    id_ine_cadastro,
    nome_esf_cadastro,
    'Renal' AS categoria,
    'IRC' AS agravo,
    COUNT(IF(IRC IS NOT NULL, 1, NULL)) AS n_pessoas
  FROM base_dm
  GROUP BY 1,2,3,4,5

  UNION ALL

  -- Cardiopatia isquêmica
  SELECT
    area_programatica_cadastro,
    id_cnes_cadastro,
    nome_clinica_cadastro,
    id_ine_cadastro,
    nome_esf_cadastro,
    'Cardiovascular' AS categoria,
    'Cardiopatia isquêmica' AS agravo,
    COUNT(IF(CI IS NOT NULL, 1, NULL)) AS n_pessoas
  FROM base_dm
  GROUP BY 1,2,3,4,5

  UNION ALL

  -- Insuficiência cardíaca
  SELECT
    area_programatica_cadastro,
    id_cnes_cadastro,
    nome_clinica_cadastro,
    id_ine_cadastro,
    nome_esf_cadastro,
    'Cardiovascular' AS categoria,
    'Insuficiência cardíaca' AS agravo,
    COUNT(IF(ICC IS NOT NULL, 1, NULL)) AS n_pessoas
  FROM base_dm
  GROUP BY 1,2,3,4,5

  UNION ALL

  -- AVC
  SELECT
    area_programatica_cadastro,
    id_cnes_cadastro,
    nome_clinica_cadastro,
    id_ine_cadastro,
    nome_esf_cadastro,
    'Cardiovascular' AS categoria,
    'AVC' AS agravo,
    COUNT(IF(stroke IS NOT NULL, 1, NULL)) AS n_pessoas
  FROM base_dm
  GROUP BY 1,2,3,4,5

  UNION ALL

  -- Doença vascular periférica
  SELECT
    area_programatica_cadastro,
    id_cnes_cadastro,
    nome_clinica_cadastro,
    id_ine_cadastro,
    nome_esf_cadastro,
    'Cardiovascular' AS categoria,
    'Doença vascular periférica' AS agravo,
    COUNT(IF(vascular_periferica IS NOT NULL, 1, NULL)) AS n_pessoas
  FROM base_dm
  GROUP BY 1,2,3,4,5

  UNION ALL

  -- Arritmia
  SELECT
    area_programatica_cadastro,
    id_cnes_cadastro,
    nome_clinica_cadastro,
    id_ine_cadastro,
    nome_esf_cadastro,
    'Cardiovascular' AS categoria,
    'Arritmia' AS agravo,
    COUNT(IF(arritmia IS NOT NULL, 1, NULL)) AS n_pessoas
  FROM base_dm
  GROUP BY 1,2,3,4,5

  UNION ALL

  -- Doença valvar
  SELECT
    area_programatica_cadastro,
    id_cnes_cadastro,
    nome_clinica_cadastro,
    id_ine_cadastro,
    nome_esf_cadastro,
    'Cardiovascular' AS categoria,
    'Doença valvar' AS agravo,
    COUNT(IF(valvular IS NOT NULL, 1, NULL)) AS n_pessoas
  FROM base_dm
  GROUP BY 1,2,3,4,5

  UNION ALL

  -- Acometimento visual
  SELECT
    area_programatica_cadastro,
    id_cnes_cadastro,
    nome_clinica_cadastro,
    id_ine_cadastro,
    nome_esf_cadastro,
    'Complicações' AS categoria,
    'Acometimento visual' AS agravo,
    COUNT(IF(olhos IS NOT NULL, 1, NULL)) AS n_pessoas
  FROM base_dm
  GROUP BY 1,2,3,4,5

  UNION ALL

  -- Tabagismo
  SELECT
    area_programatica_cadastro,
    id_cnes_cadastro,
    nome_clinica_cadastro,
    id_ine_cadastro,
    nome_esf_cadastro,
    'Hábitos de vida' AS categoria,
    'Tabagismo' AS agravo,
    COUNT(IF(IFNULL(tem_tabagismo, FALSE), 1, NULL)) AS n_pessoas
  FROM base_dm
  GROUP BY 1,2,3,4,5

  UNION ALL

  -- Uso de álcool
  SELECT
    area_programatica_cadastro,
    id_cnes_cadastro,
    nome_clinica_cadastro,
    id_ine_cadastro,
    nome_esf_cadastro,
    'Hábitos de vida' AS categoria,
    'Uso de álcool' AS agravo,
    COUNT(IF(IFNULL(tem_alcool, FALSE), 1, NULL)) AS n_pessoas
  FROM base_dm
  GROUP BY 1,2,3,4,5
)

SELECT
  a.area_programatica_cadastro,
  a.id_cnes_cadastro,
  a.nome_clinica_cadastro,
  a.id_ine_cadastro,
  a.nome_esf_cadastro,
  a.categoria,
  a.agravo,
  a.n_pessoas,
  d.total_pessoas_dm
FROM agravos a
LEFT JOIN denominador d
  USING (
    area_programatica_cadastro,
    id_cnes_cadastro,
    nome_clinica_cadastro,
    id_ine_cadastro,
    nome_esf_cadastro
  );
