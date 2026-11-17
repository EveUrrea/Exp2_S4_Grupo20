/* =====================================================================
   CASO 1: LISTADO DE TRABAJADORES
   ===================================================================== */
SELECT UPPER(TRIM(t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno))
           AS "Nombre Completo Trabajador",
       TO_CHAR(t.numrut, 'FM999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')
           || '-' || UPPER(t.dvrut) AS "RUT Trabajador",
       UPPER(tt.desc_categoria) AS "Tipo Trabajador",
       UPPER(cc.nombre_ciudad) AS "Ciudad Trabajador",
       TO_CHAR(NVL(t.sueldo_base, 0), '$999G999G999',
               'NLS_NUMERIC_CHARACTERS='',.''') AS "Sueldo Base"
FROM trabajador t
     INNER JOIN comuna_ciudad cc
         ON cc.id_ciudad = t.id_ciudad
     INNER JOIN tipo_trabajador tt
         ON tt.id_categoria = t.id_categoria_t
WHERE t.sueldo_base BETWEEN 650000 AND 3000000
ORDER BY cc.nombre_ciudad DESC,
         t.sueldo_base ASC;

/* =====================================================================
   CASO 2: LISTADO DE CAJEROS
   ===================================================================== */
SELECT TO_CHAR(t.numrut, 'FM999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')
           || '-' || UPPER(t.dvrut) AS "RUT Trabajador",
       INITCAP(LOWER(t.nombre)) || ' ' || UPPER(t.appaterno)
           AS "Nombre Trabajador",
       COUNT(DISTINCT tk.nro_ticket) AS "Total Tickets",
       TO_CHAR(SUM(tk.monto_ticket), '$999G999G999',
               'NLS_NUMERIC_CHARACTERS='',.''') AS "Total Vendido",
       TO_CHAR(SUM(NVL(ct.valor_comision, 0)), '$999G999G999',
               'NLS_NUMERIC_CHARACTERS='',.''') AS "Comisión Total",
       UPPER(tt.desc_categoria) AS "Tipo Trabajador",
       UPPER(cc.nombre_ciudad) AS "Ciudad Trabajador"
FROM trabajador t
     INNER JOIN tipo_trabajador tt
         ON tt.id_categoria = t.id_categoria_t
     INNER JOIN comuna_ciudad cc
         ON cc.id_ciudad = t.id_ciudad
     INNER JOIN tickets_concierto tk
         ON tk.numrut_t = t.numrut
     LEFT JOIN comisiones_ticket ct
         ON ct.nro_ticket = tk.nro_ticket
WHERE UPPER(tt.desc_categoria) = 'CAJERO'
GROUP BY t.numrut,
         t.dvrut,
         t.nombre,
         t.appaterno,
         tt.desc_categoria,
         cc.nombre_ciudad
HAVING SUM(tk.monto_ticket) > 50000
ORDER BY SUM(tk.monto_ticket) DESC;

/* =====================================================================
   CASO 3: LISTADO DE BONIFICACIONES
   ===================================================================== */
SELECT TO_CHAR(t.numrut, 'FM999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')
           || '-' || UPPER(t.dvrut) AS "RUT Trabajador",
       INITCAP(LOWER(t.nombre)) || ' ' || INITCAP(LOWER(t.appaterno))
           AS "Trabajador Nombre",
       TO_CHAR(t.fecing, 'YYYY') AS "Año Ingreso",
       TRUNC(MONTHS_BETWEEN(SYSDATE, t.fecing) / 12)
           AS "Años Antigüedad",
       COUNT(DISTINCT af.numrut_carga) AS "Num. Cargas Familiares",
       INITCAP(LOWER(i.nombre_isapre)) AS "Nombre Isapre",
       TO_CHAR(NVL(t.sueldo_base, 0), '$999G999G999',
               'NLS_NUMERIC_CHARACTERS='',.''') AS "Sueldo Base",
       TO_CHAR(
           ROUND(CASE
                     WHEN UPPER(i.nombre_isapre) = 'FONASA'
                     THEN t.sueldo_base * 0.01
                     ELSE 0
                 END),
           '$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''') AS "Bono Fonasa",
       TO_CHAR(ROUND(t.sueldo_base * ba.porcentaje / 100),
               '$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')
           AS "Bono Antigüedad",
       INITCAP(LOWER(a.nombre_afp)) AS "Nombre AFP",
       UPPER(ec.desc_estcivil) AS "Estado Civil"
FROM trabajador t
     INNER JOIN est_civil e
         ON e.numrut_t = t.numrut
        AND (e.fecter_estcivil IS NULL OR e.fecter_estcivil > SYSDATE)
     INNER JOIN estado_civil ec
         ON ec.id_estcivil = e.id_estcivil_est
     LEFT JOIN asignacion_familiar af
         ON af.numrut_t = t.numrut
     INNER JOIN isapre i
         ON i.cod_isapre = t.cod_isapre
     INNER JOIN afp a
         ON a.cod_afp = t.cod_afp
     INNER JOIN bono_antiguedad ba
         ON TRUNC(MONTHS_BETWEEN(SYSDATE, t.fecing) / 12)
            BETWEEN ba.limite_inferior AND ba.limite_superior
GROUP BY t.numrut,
         t.dvrut,
         t.nombre,
         t.appaterno,
         t.fecing,
         i.nombre_isapre,
         t.sueldo_base,
         ba.porcentaje,
         a.nombre_afp,
         ec.desc_estcivil
ORDER BY t.numrut ASC;
