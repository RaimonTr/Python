---PRUEBA FILTRADA
-- Esta consulta obtiene una "foto" de la deuda B2B para una fecha específica,
-- aplicando filtros de origen, estado y segmentación de cliente.
/* Orígenes:
		ed_owner.t_ed_f_sap_reg_deuda_b2b AS rc
		ed_owner.t_ed_h_sap_reg_deuda AS deuda
		ed_owner.T_ED_H_SAP_CUENTA_CONTRATO AS cta_crto
 */
SELECT
  -- Fecha de ejecución (YYYYMMDD) que actúa como "snapshot"
  to_char(rc.fh_ejec) as fh_ejec,
  -- Información organizativa del cliente
  rc.subdireccion,    -- Subdirección responsable
  rc.territorio,      -- Territorio comercial
  rc.segmento,        -- Segmento de negocio
  CASE WHEN rc.zona = '' THEN 'No informada' ELSE rc.zona END AS d_zona,  ---Zona geográfica (fallback si vacío)
  -- Datos de proceso de cobro
  rc.posicion,        -- Posición en flujo de cobro
  rc.gestor,          -- Gestor asignado
  -- Clasificación público/privado según grupo 2
  CASE 
    WHEN rc.ddd_grp2 IN (11,12,13,14,21,22,23,24) THEN 'PUBLICO'    ---Agrupo los OR en un IN para mayor claridad
    WHEN rc.ddd_grp2 IN (3,4)                   THEN 'PRIVADO'     ---Agrupo los OR en un IN para mayor claridad
    ELSE ' '
  END AS d_tipo_cliente,
  -- Atributos de cliente y deuda
  rc.tipo_cliente            AS Deuda_tipo_cliente,  -- Tipo original de cliente
  rc.cd_cliente,                                  -- Código interno de cliente
  rc.cif,                                         -- CIF/NIF
  rc.razon_social,                                -- Razón social
  rc.cd_codpost,                                  -- Código postal
  rc.cnae_riesgo,                                 -- Riesgo según CNAE
  'Buscar Lógica'            AS cnae_actividad,   -- Placeholder actividad económica
  -- Identificadores de contrato y factura
  rc.id_crto_ext,      -- ID de contrato externo
  rc.id_crto_sap,      -- ID de contrato SAP
  rc.sociedad,         -- Código de sociedad
  rc.id_fact,          -- ID de factura
  rc.cd_partida,       -- Partida dentro de factura
  -- Datos de la tabla histórica de deuda
  deuda.cd_posicion,   -- Posición histórica
  deuda.de_clase_doc,  -- Clase documental
  -- Información tarifaria
  rc.cd_cups_ext,      -- Código de punto de suministro
  rc.cd_tarifa,        -- Tarifa aplicada
  rc.nm_max_pot_ctada, -- Potencia contratada máxima
  -- Scoring de deuda: valida nm_vrec y aplica reglas de negocio en null
  CASE
    WHEN rc.nm_vrec IS NULL AND rc.nm_score = -1                      THEN -2
    WHEN rc.nm_vrec IS NULL AND rc.nm_score IS NULL                   THEN -1
    WHEN rc.nm_vrec IS NULL AND rc.nm_score > 0 AND rc.nm_score < 100 THEN rc.nm_score * 10
    WHEN rc.nm_vrec IS NULL AND rc.nm_score > 100                     THEN -2
    WHEN rc.nm_vrec IS NULL AND rc.nm_score = 0                        THEN 0
    ELSE rc.nm_vrec                                                  -- Valor original si no es NULL
  END AS Deuda_Scoring,
  -- Fechas de facturación y cobro
  rc.fh_fact,          -- Fecha de emisión de factura
  rc.fh_limpago,       -- Fecha límite de pago
  -- Indicador de fraccionamiento (0=sin, 1=con fracc.)
  CASE WHEN rc.cd_ppp IS NULL THEN '0' ELSE '1' END AS Deuda_flag_fraccionamiento,
  -- Periodo de facturación detallado
  rc.fh_fact_des,      -- Desde
  rc.fh_fact_has,      -- Hasta
  rc.fh_fin_plaz,      -- Fin de plazo de pago
  -- Estado de contrato y cobro
  rc.fh_alta_cont,     -- Alta contrato
  rc.fh_baja_cont,     -- Baja contrato
  rc.fh_cobro,         -- Fecha de intento de cobro
  rc.de_estado,        -- Estado general de deuda
  -- Detalles internos DDD
  rc.ddd_territorio,   -- Identificador territorio interno
  -- Línea de negocio (Luz, Gas, SD, Varios)
  CASE
    WHEN rc.cd_tp_fact IN ('ZACL','ZGAP','ZCLI','ZREC','ZAGA') THEN 'Varios'  ---Agrupo los OR en un IN para mayor claridad
    WHEN rc.cd_tp_fact = 'SD'                                THEN 'SD'
    WHEN rc.cd_tp_fact NOT IN ('ZACL','ZGAP','ZCLI','ZREC','ZAGA','SD')
         AND rc.cd_linea_negocio::integer = 1                THEN 'Electricidad'
    WHEN rc.cd_tp_fact NOT IN ('ZACL','ZGAP','ZCLI','ZREC','ZAGA','SD')
         AND rc.cd_linea_negocio::integer = 2                THEN 'Gas'
  END AS d_linea_negocio,
  -- Tratamiento de gestión
  CASE WHEN rc.lg_tratamiento_masivo = 1 THEN 'Masivo' ELSE 'Personalizado' END AS circuito,
  -- Servicio asociado y esencialidad
  rc.ddd_soluempr,     -- Código de servicio empresarial
  CASE WHEN rc.ddd_esencial = 1 THEN 'Esencial' ELSE 'No esencial' END AS d_ddd_esencial,
  -- Indicadores adicionales de deuda
  deuda.ddd_cortable,  -- Puede ser cortable
  rc.ddd_pnt,          -- Punto de red
  rc.ddd_sva,          -- Servicio valor añadido
  -- Modo de pago domiciliado vs no domiciliado
  CASE WHEN rc.cd_via_pago = 'D' THEN 'Domiciliado'
       WHEN rc.cd_via_pago = 'N' THEN 'No domiciliado'
  END AS modo_pago,
  deuda.de_cond_pago,  -- Condiciones de pago históricas
  'Buscar Lógica'      AS gestion,               -- Placeholder para lógica de gestión
  deuda.lg_cliente_concursal, -- Indicador concursal
  -- Canales DDD de deuda desglosados
  rc.ddd_ar     AS Deuda_ddd_ar,
  rc.ddd_aj     AS Deuda_ddd_aj,
  rc.ddd_pc     AS Deuda_ddd_pc,
  rc.ddd_ge     AS Deuda_ddd_ge,
  rc.ddd_fallcont,
  rc.ddd_grp1,
  rc.ddd_grp2,
  rc.ddd_grp3,
  -- Información de paralización y vía judicial
  rc.cd_motiv_paralizacion,
  rc.fh_concurso,
  rc.cd_agencia_recobro,
  rc.cd_despacho,
  rc.fh_entrega_ar,
  rc.fh_entrega_aj,
  rc.fh_paso_judicial,
  deuda.ddd_reclam,
  -- Flag de deuda vencida: 0 si no vencida; 1 si vencida
  CASE
    WHEN (
      to_char(rc.fh_limpago,'YYYYMMDD')::integer >  rc.fh_ejec    ---Lo saco en varias líneas para mayor claridad respecto a v1
      OR to_char(rc.fh_limpago,'YYYYMMDD')::integer =  rc.fh_ejec
      OR (
        to_char(rc.fh_limpago,'YYYYMMDD')::integer = 14000101
        AND rc.ddd_vencida = 0
      )
    ) AND rc.ddd_ge <> 5 THEN 0
    ELSE 1
  END AS deuda_flag_vencida,
  deuda.circuito_impago, -- Circuito de impago histórico
  -- Traducción de códigos de estado ordinario a texto
  CASE
    WHEN rc.cd_est_impago = 'C999'           THEN 'Aviso Pago'  ---Agrupo los or en un IN para mayor claridad
    WHEN rc.cd_est_impago = 'C001'           THEN 'Aviso Impago'
    WHEN rc.cd_est_impago IN ('C002','C003') THEN 'Aviso Corte'
    WHEN rc.cd_est_impago IN ('C004','C005') THEN 'Ejec Corte'
    WHEN rc.cd_est_impago = 'C006'           THEN 'Aviso Baja'
    WHEN rc.cd_est_impago IN ('C007','CC00') THEN 'Baja Contrato con Deuda'
    ELSE 'Otro'
  END AS Estado_Ordinaria,
  -- Fechas y estados de acuse y rehu
  deuda.de_est_acuse,
  deuda.fh_alta_acuse,
  deuda.fh_fir_rehu,
  deuda.fh_caduc_fehaciencia,
  deuda.ddd_avisado,
  deuda.ddd_fehaciente,
  deuda.cd_tp_bloq_doc,
  deuda.cd_tp_bloq_cta,
  -- Tensión/presión del punto (join con tabla auxiliar)
  ps.de_tension_presion AS tension,
  rc.cd_tp_fact,
 --MÓDULO DE CLASIFICACIÓN DE DEUDA
	 -- Importes vencidos y no vencidos por condiciones de fecha y flags
  CASE WHEN (to_char(rc.fh_limpago, 'YYYYMMDD')::integer > rc.fh_ejec
             or to_char(rc.fh_limpago, 'YYYYMMDD')::integer = rc.fh_ejec
             or (to_char(rc.fh_limpago, 'YYYYMMDD')::integer=14000101 and rc.ddd_vencida = 0))
            and rc.ddd_ge <> 5 THEN (rc.im_partida)
  END as Deuda_No_Vencida,
  CASE WHEN (to_char(rc.fh_limpago, 'YYYYMMDD')::integer < rc.fh_ejec
             and to_char(rc.fh_limpago, 'YYYYMMDD')::integer <> 14000101 and rc.ddd_ge <> 5)
            or (to_char(rc.fh_limpago, 'YYYYMMDD')::integer = 14000101 and rc.ddd_vencida = 1 and rc.ddd_ge <> 5)
       THEN (rc.im_partida)
  END as Deuda_Vencida,
  CASE WHEN (to_char(rc.fh_limpago, 'YYYYMMDD')::integer < rc.fh_ejec
             and to_char(rc.fh_limpago, 'YYYYMMDD')::integer <> 14000101 and rc.ddd_ge = 1)
            or (to_char(rc.fh_limpago, 'YYYYMMDD')::integer = 14000101 and rc.ddd_vencida = 1 and rc.ddd_ge = 1)
       THEN (rc.im_partida)
  END as Deuda_Vencida_Ordinaria,
  CASE WHEN (to_char(rc.fh_limpago, 'YYYYMMDD')::integer < rc.fh_ejec
             and to_char(rc.fh_limpago, 'YYYYMMDD')::integer <> 14000101 and rc.ddd_ge = 2)
            or (to_char(rc.fh_limpago, 'YYYYMMDD')::integer = 14000101 and rc.ddd_vencida = 1 and rc.ddd_ge = 2)
       THEN (rc.im_partida)
  END as Deuda_Vencida_AR,
  CASE WHEN (to_char(rc.fh_limpago, 'YYYYMMDD')::integer < rc.fh_ejec
             and to_char(rc.fh_limpago, 'YYYYMMDD')::integer <> 14000101 and rc.ddd_ge = 3)
            or (to_char(rc.fh_limpago, 'YYYYMMDD')::integer = 14000101 and rc.ddd_vencida = 1 and rc.ddd_ge = 3)
       THEN (rc.im_partida)
  END as Deuda_Vencida_AJ,
  CASE WHEN (to_char(rc.fh_limpago, 'YYYYMMDD')::integer < rc.fh_ejec
             and to_char(rc.fh_limpago, 'YYYYMMDD')::integer <> 14000101 and rc.ddd_ge = 4)
            or (to_char(rc.fh_limpago, 'YYYYMMDD')::integer = 14000101 and rc.ddd_vencida = 1 and rc.ddd_ge = 4)
       THEN (rc.im_partida)
  END as Deuda_Vencida_PC,
  CASE WHEN (to_char(rc.fh_limpago, 'YYYYMMDD')::integer < rc.fh_ejec
             and to_char(rc.fh_limpago, 'YYYYMMDD')::integer <> 14000101 and rc.ddd_ge = 3 and rc.ddd_pc < 2)
            or (to_char(rc.fh_limpago, 'YYYYMMDD')::integer = 14000101 and rc.ddd_vencida = 1 and rc.ddd_ge = 3)
       THEN (rc.im_partida)
  END as Deuda_Vencida_NoPostC,
  CASE WHEN (to_char(rc.fh_limpago, 'YYYYMMDD')::integer < rc.fh_ejec
             and to_char(rc.fh_limpago, 'YYYYMMDD')::integer <> 14000101 and rc.ddd_ge = 3 and rc.ddd_pc = 2)
            or (to_char(rc.fh_limpago, 'YYYYMMDD')::integer = 14000101 and rc.ddd_vencida = 1 and rc.ddd_ge = 3)
       THEN (rc.im_partida)
  END as Deuda_Vencida_PostC,
  CASE WHEN (
      to_char(rc.fh_limpago,'YYYYMMDD')::integer <  rc.fh_ejec
      AND to_char(rc.fh_limpago,'YYYYMMDD')::integer <> 14000101
      AND rc.ddd_ge = 3 AND rc.ddd_pc = 2
    ) OR (
      to_char(rc.fh_limpago,'YYYYMMDD')::integer = 14000101
      AND rc.ddd_vencida = 1 AND rc.ddd_ge = 3
    ) THEN rc.im_partida END AS Deuda_Vencida_PostC,
  -- Segmentación de riesgo y cliente (solo descripción)
  rc.de_seg_grupo,
  rc.de_seg_sociedad,
  CASE
    WHEN rc.de_seg_grupo = 'RIII' OR rc.de_seg_sociedad = 'RIII' THEN 'RIII'
    WHEN rc.de_seg_grupo = 'RII' OR rc.de_seg_sociedad = 'RII'   THEN 'RII'
    WHEN rc.de_seg_grupo = 'RI'  OR rc.de_seg_sociedad = 'RI'    THEN 'RI'
    ELSE 'Sin informar'
  END AS segmento_riesgos,
  ---cta_crto.cd_seg_cliente,                          ---Elimino la columna con el código
  ---Establece si el origen de la deuda es Rosetta o Cosmos
  CASE 
    WHEN cta_crto.cd_seg_cliente = '001' THEN 'ROSETTA'
    WHEN cta_crto.cd_seg_cliente = '002' THEN 'COSMOS'
    ELSE ''
  END AS de_seg_cliente                                  ---Descripción de origen
  ---Uniones para conocer el origen de la deuda R o C
FROM ed_owner.t_ed_f_sap_reg_deuda_b2b AS rc   ---En el código de muestra que ma pasó Santi se llama originalmente "deuda"
LEFT JOIN ed_owner.t_ed_h_sap_reg_deuda AS deuda  ---Originalmente se llamaba "cta_crto"
  ON rc.fh_ejec         = deuda.fh_ejec
 AND rc.cd_partida      = deuda.cd_partida
 AND rc.nm_posicion     = deuda.cd_posicion
 AND rc.nm_pos_parcial  = deuda.cd_posicion_parcial
 AND rc.cd_sociedad     = deuda.cd_sociedad
LEFT JOIN 
	(
	  SELECT
	    COALESCE(de_cups_22, de_cups_20)  AS cups,     ---Cambio NVL por COALESCE (ANSI SQL)
	    de_tension_presion
	  FROM ed_owner.t_ed_f_stros_sf
	) 
AS ps
  ON ps.cups = rc.cd_cups_ext
INNER JOIN ed_owner.T_ED_H_SAP_CUENTA_CONTRATO AS cta_crto
  ON rc.cd_cliente  = cta_crto.cd_interloc_comer
 AND rc.cd_cta_crto = cta_crto.cd_cuenta_contr
WHERE
  LEFT(rc.cif,2) NOT IN ('FR','NL')   ---Excluyo CIFs de Francia, Países Bajos
 AND rc.ddd_ge      <> 5                     ---Excluir gestiones archivadas
 AND rc.fh_ejec     = '20251006'            ---Fecha de la "foto" de deuda
 AND rc.cd_est_impago <> 'C000'             ---Quita las cuotas ya cobradas
 AND UPPER(deuda.de_est_impago) <> 'ANULADA'---Quita las anuladas
 AND (CASE WHEN rc.cd_ppp <> 0 THEN 1 ELSE 0 END) <> 1  ---Quita registros "madre"
 AND rc.cd_sociedad <> 'ES5R'              ---Excluir sociedad ES5R (Zuora)