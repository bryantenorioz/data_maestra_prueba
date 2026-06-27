-- Pregunta 5: Detección de solicitudes duplicadas o anómalas

-- Una solicitud que regresó a una etapa anterior (el mismo estado aparece más de una vez en el log para la misma solicitud), O
-- Una solicitud que tardó más del doble del SLA de su categoría

WITH FLUJ_IRREG AS (
SELECT DISTINCT ID_SOLICITUD,
       1 FLG_FLJ_IRREG
  FROM (
SELECT ID_SOLICITUD,
       ESTADO_ETAPA,
       COUNT(*)
  FROM `first-project-500415.data_maestra_prueba.log_cambios_estado`
 GROUP BY ID_SOLICITUD, ESTADO_ETAPA
 HAVING COUNT(*) > 1
)
),
EXC_SLA AS (
SELECT A.ID_SOLICITUD,
       C.CATEGORIA,
       A.ESTADO ESTADO_FINAL,
       A.DIAS_CICLO,
       B.SLA_DIAS_HABILES SLA_APLICABLE,
       CASE
         WHEN A.DIAS_CICLO > 2 * B.SLA_DIAS_HABILES THEN 1
         ELSE 0
       END FLG_2X_SLA
  FROM `first-project-500415.data_maestra_prueba.solicitudes_material` A
  LEFT JOIN `first-project-500415.data_maestra_prueba.sla_por_categoria` B
    ON A.ID_CATEGORIA = B.ID_CATEGORIA
  LEFT JOIN `first-project-500415.data_maestra_prueba.categorias` C
    ON A.ID_CATEGORIA = C.ID_CATEGORIA
)
SELECT A.ID_SOLICITUD,
       A.CATEGORIA,
       A.ESTADO_FINAL,
       A.DIAS_CICLO,
       A.SLA_APLICABLE,
       CASE
         WHEN A.FLG_2X_SLA = 1 AND IFNULL(B.FLG_FLJ_IRREG, 0) = 1 THEN 'Ambas'
         WHEN A.FLG_2X_SLA = 1 THEN 'Excede x2 SLA'
         WHEN IFNULL(B.FLG_FLJ_IRREG, 0) = 1 THEN 'Flujo irregular'
       END MOTIVO_ANOMALIA
  FROM EXC_SLA A
  LEFT JOIN FLUJ_IRREG B
    ON A.ID_SOLICITUD = B.ID_SOLICITUD
  WHERE A.FLG_2X_SLA = 1
     OR IFNULL(B.FLG_FLJ_IRREG, 0) = 1;