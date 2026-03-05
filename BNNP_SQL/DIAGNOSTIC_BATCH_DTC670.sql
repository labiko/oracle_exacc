-- ============================================================
-- DIAGNOSTIC BATCH DTC670/BAATGS - Ou en est le traitement ?
-- ============================================================
-- Date : 20/02/2026
-- Usage : Executer pour voir l'etat reel du batch
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 300
SET PAGESIZE 100
SET TIMING OFF

PROMPT ============================================================
PROMPT DIAGNOSTIC BATCH DTC670/BAATGS
PROMPT ============================================================

-- ============================================================
-- 1. JOBS SCHEDULER EN COURS
-- ============================================================
PROMPT
PROMPT [1/7] Jobs Scheduler en cours d'execution...
PROMPT ============================================================

SELECT
    JOB_NAME,
    SESSION_ID AS SID,
    RUNNING_INSTANCE,
    ELAPSED_TIME,
    CPU_USED,
    TO_CHAR(JOB_START_TIME, 'DD/MM/YYYY HH24:MI:SS') AS DEBUT
FROM DBA_SCHEDULER_RUNNING_JOBS
WHERE UPPER(JOB_NAME) LIKE '%BAATGS%'
   OR UPPER(JOB_NAME) LIKE '%DTC670%'
   OR UPPER(JOB_NAME) LIKE '%RNADEXT%'
   OR UPPER(JOB_NAME) LIKE '%PKG_RNA%';

-- ============================================================
-- 2. TOUS LES JOBS SCHEDULER EN COURS (si le nom n'est pas standard)
-- ============================================================
PROMPT
PROMPT [2/7] Tous les jobs Scheduler en cours...
PROMPT ============================================================

SELECT
    JOB_NAME,
    OWNER,
    SESSION_ID AS SID,
    RUNNING_INSTANCE,
    ELAPSED_TIME,
    CPU_USED,
    TO_CHAR(JOB_START_TIME, 'DD/MM/YYYY HH24:MI:SS') AS DEBUT
FROM DBA_SCHEDULER_RUNNING_JOBS;

-- ============================================================
-- 3. SESSIONS EXECUTANT PKG_RNADEXTAUTO01
-- ============================================================
PROMPT
PROMPT [3/7] Sessions executant PKG_RNADEXTAUTO01...
PROMPT ============================================================

SELECT
    s.SID,
    s.SERIAL#,
    s.USERNAME,
    s.STATUS,
    s.EVENT,
    s.WAIT_CLASS,
    s.SECONDS_IN_WAIT AS WAIT_SEC,
    s.SQL_ID,
    SUBSTR(s.PROGRAM, 1, 40) AS PROGRAM,
    TO_CHAR(s.LOGON_TIME, 'DD/MM HH24:MI') AS LOGON
FROM V$SESSION s
WHERE s.USERNAME IS NOT NULL
  AND (
      s.ACTION LIKE '%RNADEXT%'
   OR s.MODULE LIKE '%RNADEXT%'
   OR s.CLIENT_INFO LIKE '%BAATGS%'
   OR s.SQL_ID IN (
       SELECT SQL_ID FROM V$SQL
       WHERE UPPER(SQL_TEXT) LIKE '%PKG_RNADEXTAUTO01%'
          OR UPPER(SQL_TEXT) LIKE '%BA_ATTENDUS_GEST%'
          OR UPPER(SQL_TEXT) LIKE '%BRR_TRANSACTIONS%'
   )
  )
ORDER BY s.LOGON_TIME;

-- ============================================================
-- 4. REQUETES SQL EN COURS SUR BRR_TRANSACTIONS
-- ============================================================
PROMPT
PROMPT [4/7] Requetes SQL actives sur BRR_TRANSACTIONS...
PROMPT ============================================================

SELECT
    s.SID,
    s.SERIAL#,
    s.USERNAME,
    s.STATUS,
    s.EVENT,
    s.SECONDS_IN_WAIT AS WAIT_SEC,
    sq.SQL_ID,
    sq.ELAPSED_TIME/1000000 AS ELAPSED_SEC,
    sq.EXECUTIONS,
    sq.BUFFER_GETS,
    sq.DISK_READS,
    SUBSTR(sq.SQL_TEXT, 1, 100) AS SQL_TEXT_100
FROM V$SESSION s
JOIN V$SQL sq ON sq.SQL_ID = s.SQL_ID
WHERE s.STATUS = 'ACTIVE'
  AND s.USERNAME IS NOT NULL
  AND UPPER(sq.SQL_TEXT) LIKE '%BRR_TRANSACTIONS%'
ORDER BY sq.ELAPSED_TIME DESC;

-- ============================================================
-- 5. LONG OPERATIONS (queries longues)
-- ============================================================
PROMPT
PROMPT [5/7] Long Operations en cours...
PROMPT ============================================================

SELECT
    SID,
    SERIAL#,
    OPNAME,
    TARGET,
    SOFAR,
    TOTALWORK,
    ROUND(SOFAR/NULLIF(TOTALWORK,0)*100, 2) AS PCT_DONE,
    ELAPSED_SECONDS,
    TIME_REMAINING AS REMAINING_SEC,
    SQL_ID,
    MESSAGE
FROM V$SESSION_LONGOPS
WHERE SOFAR < TOTALWORK
   OR TIME_REMAINING > 0
ORDER BY START_TIME DESC;

-- ============================================================
-- 6. I/O WAIT (Attentes disque)
-- ============================================================
PROMPT
PROMPT [6/7] Sessions en attente I/O...
PROMPT ============================================================

SELECT
    s.SID,
    s.SERIAL#,
    s.USERNAME,
    s.EVENT,
    s.WAIT_CLASS,
    s.SECONDS_IN_WAIT AS WAIT_SEC,
    s.SQL_ID,
    SUBSTR(s.PROGRAM, 1, 30) AS PROGRAM
FROM V$SESSION s
WHERE s.WAIT_CLASS = 'User I/O'
  AND s.USERNAME IS NOT NULL
ORDER BY s.SECONDS_IN_WAIT DESC;

-- ============================================================
-- 7. SQL_ID 4v9ag77cam8uu (DTC670 specifique)
-- ============================================================
PROMPT
PROMPT [7/7] SQL_ID 4v9ag77cam8uu (DTC670)...
PROMPT ============================================================

SELECT
    SQL_ID,
    EXECUTIONS,
    ROUND(ELAPSED_TIME/1000000, 2) AS ELAPSED_SEC,
    ROUND(CPU_TIME/1000000, 2) AS CPU_SEC,
    BUFFER_GETS,
    DISK_READS,
    ROWS_PROCESSED,
    PLAN_HASH_VALUE
FROM V$SQL
WHERE SQL_ID = '4v9ag77cam8uu';

-- ============================================================
-- RESUME - Que faire selon les resultats
-- ============================================================
PROMPT
PROMPT ============================================================
PROMPT INTERPRETATION DES RESULTATS
PROMPT ============================================================
PROMPT
PROMPT Si [3/7] ou [4/7] montrent une session :
PROMPT   -> Le batch est en cours, note le SID et SQL_ID
PROMPT   -> Verifie [6/7] pour voir s'il attend les I/O
PROMPT
PROMPT Si [5/7] montre une progression :
PROMPT   -> Note le PCT_DONE et TIME_REMAINING
PROMPT   -> Le batch avance, mais lentement (I/O bottleneck)
PROMPT
PROMPT Si [6/7] montre des sessions en "User I/O" :
PROMPT   -> Confirme le goulot I/O (98% disk utilization)
PROMPT   -> La seule solution = optimiser la requete (notre CTE)
PROMPT
PROMPT Si TOUT est vide :
PROMPT   -> Le batch est peut-etre en erreur
PROMPT   -> Verifier DBA_SCHEDULER_JOB_RUN_DETAILS
PROMPT
PROMPT ============================================================

-- ============================================================
-- BONUS : Verifier l'historique recent du job
-- ============================================================
PROMPT
PROMPT [BONUS] Historique recent du job...
PROMPT ============================================================

SELECT
    JOB_NAME,
    STATUS,
    TO_CHAR(ACTUAL_START_DATE, 'DD/MM/YYYY HH24:MI:SS') AS DEBUT,
    RUN_DURATION,
    ERROR#,
    SUBSTR(ADDITIONAL_INFO, 1, 100) AS INFO
FROM DBA_SCHEDULER_JOB_RUN_DETAILS
WHERE ACTUAL_START_DATE > SYSDATE - 1
  AND (UPPER(JOB_NAME) LIKE '%BAATGS%'
    OR UPPER(JOB_NAME) LIKE '%DTC670%'
    OR UPPER(JOB_NAME) LIKE '%RNADEXT%')
ORDER BY ACTUAL_START_DATE DESC
FETCH FIRST 10 ROWS ONLY;

PROMPT
PROMPT ============================================================
PROMPT FIN DIAGNOSTIC
PROMPT ============================================================
