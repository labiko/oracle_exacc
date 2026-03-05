-- ============================================================
-- DIAGNOSTIC RAPIDE - Ou est le batch DTC670 ?
-- ============================================================
-- 3 requetes essentielles pour diagnostic immediat
-- ============================================================

SET LINESIZE 200
SET PAGESIZE 50

-- 1. Jobs Scheduler en cours
PROMPT [1/3] Jobs Scheduler actifs...
SELECT JOB_NAME, SESSION_ID AS SID, ELAPSED_TIME, TO_CHAR(JOB_START_TIME, 'DD/MM HH24:MI:SS') AS DEBUT
FROM DBA_SCHEDULER_RUNNING_JOBS;

-- 2. Sessions actives avec SQL sur BRR_TRANSACTIONS ou BA_ATTENDUS_GEST
PROMPT
PROMPT [2/3] Sessions actives (requetes longues)...
SELECT s.SID, s.SERIAL#, s.USERNAME, s.STATUS, s.EVENT,
       s.SECONDS_IN_WAIT AS WAIT_SEC, s.SQL_ID,
       ROUND(sq.ELAPSED_TIME/1000000/60, 1) AS ELAPSED_MIN
FROM V$SESSION s
LEFT JOIN V$SQL sq ON sq.SQL_ID = s.SQL_ID
WHERE s.STATUS = 'ACTIVE'
  AND s.USERNAME IS NOT NULL
  AND (UPPER(NVL(sq.SQL_TEXT,'x')) LIKE '%BRR_TRANSACTIONS%'
    OR UPPER(NVL(sq.SQL_TEXT,'x')) LIKE '%BA_ATTENDUS_GEST%'
    OR UPPER(NVL(sq.SQL_TEXT,'x')) LIKE '%RNADEXT%')
ORDER BY s.SECONDS_IN_WAIT DESC;

-- 3. Progression des operations longues
PROMPT
PROMPT [3/3] Long operations (progression)...
SELECT SID, OPNAME, ROUND(SOFAR/NULLIF(TOTALWORK,0)*100, 1) AS PCT_DONE,
       ELAPSED_SECONDS AS ELAPSED_SEC, TIME_REMAINING AS REMAIN_SEC, SQL_ID
FROM V$SESSION_LONGOPS
WHERE SOFAR < TOTALWORK OR TIME_REMAINING > 0
ORDER BY START_TIME DESC;

PROMPT
PROMPT ============================================================
PROMPT Si [2/3] montre un SID avec EVENT = 'db file sequential read'
PROMPT ou 'db file scattered read' => I/O bottleneck (confirme)
PROMPT
PROMPT Si tout est vide => le batch est termine ou en erreur
PROMPT Verifier : SELECT STATUS FROM DBA_SCHEDULER_JOBS WHERE JOB_NAME LIKE '%BAATGS%';
PROMPT ============================================================
