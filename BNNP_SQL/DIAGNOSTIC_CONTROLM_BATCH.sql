-- ============================================================
-- DIAGNOSTIC BATCH CONTROL-M - DTC670/BAATGS
-- ============================================================
-- Control-M lance un process externe qui se connecte a Oracle
-- On cherche directement dans V$SESSION
-- ============================================================

SET LINESIZE 250
SET PAGESIZE 100

PROMPT ============================================================
PROMPT DIAGNOSTIC BATCH CONTROL-M - DTC670/BAATGS
PROMPT ============================================================

-- ============================================================
-- 1. TOUTES LES SESSIONS ACTIVES (hors idle)
-- ============================================================
PROMPT
PROMPT [1/5] Sessions Oracle actives...
PROMPT ============================================================

SELECT
    s.SID,
    s.SERIAL#,
    s.USERNAME,
    s.STATUS,
    s.EVENT,
    s.SECONDS_IN_WAIT AS WAIT_SEC,
    s.SQL_ID,
    SUBSTR(s.PROGRAM, 1, 30) AS PROGRAM,
    SUBSTR(s.MACHINE, 1, 20) AS MACHINE,
    TO_CHAR(s.LOGON_TIME, 'DD/MM HH24:MI') AS LOGON
FROM V$SESSION s
WHERE s.STATUS = 'ACTIVE'
  AND s.USERNAME IS NOT NULL
  AND s.TYPE = 'USER'
ORDER BY s.SECONDS_IN_WAIT DESC;

-- ============================================================
-- 2. SESSIONS EXECUTANT SQL SUR BRR_TRANSACTIONS
-- ============================================================
PROMPT
PROMPT [2/5] Sessions avec SQL sur BRR_TRANSACTIONS...
PROMPT ============================================================

SELECT
    s.SID,
    s.SERIAL#,
    s.USERNAME,
    s.STATUS,
    s.EVENT,
    s.SECONDS_IN_WAIT AS WAIT_SEC,
    s.SQL_ID,
    ROUND(sq.ELAPSED_TIME/1000000/60, 1) AS ELAPSED_MIN,
    sq.EXECUTIONS,
    sq.DISK_READS,
    SUBSTR(s.PROGRAM, 1, 25) AS PROGRAM
FROM V$SESSION s
JOIN V$SQL sq ON sq.SQL_ID = s.SQL_ID
WHERE s.USERNAME IS NOT NULL
  AND (UPPER(sq.SQL_TEXT) LIKE '%BRR_TRANSACTIONS%'
    OR UPPER(sq.SQL_TEXT) LIKE '%BA_ATTENDUS_GEST%'
    OR UPPER(sq.SQL_TEXT) LIKE '%RNADEXT%')
ORDER BY sq.ELAPSED_TIME DESC;

-- ============================================================
-- 3. SQL_ID EN COURS D'EXECUTION (les plus longs)
-- ============================================================
PROMPT
PROMPT [3/5] SQL_ID les plus longs en cours...
PROMPT ============================================================

SELECT
    s.SID,
    s.SERIAL#,
    s.USERNAME,
    s.SQL_ID,
    sq.PLAN_HASH_VALUE,
    ROUND(sq.ELAPSED_TIME/1000000/60, 1) AS ELAPSED_MIN,
    sq.BUFFER_GETS,
    sq.DISK_READS,
    sq.ROWS_PROCESSED,
    SUBSTR(sq.SQL_TEXT, 1, 80) AS SQL_TEXT
FROM V$SESSION s
JOIN V$SQL sq ON sq.SQL_ID = s.SQL_ID AND sq.CHILD_NUMBER = s.SQL_CHILD_NUMBER
WHERE s.STATUS = 'ACTIVE'
  AND s.USERNAME IS NOT NULL
ORDER BY sq.ELAPSED_TIME DESC
FETCH FIRST 10 ROWS ONLY;

-- ============================================================
-- 4. LONG OPERATIONS (progression visible)
-- ============================================================
PROMPT
PROMPT [4/5] Long Operations (si progression visible)...
PROMPT ============================================================

SELECT
    SID,
    SERIAL#,
    OPNAME,
    TARGET,
    SOFAR,
    TOTALWORK,
    ROUND(SOFAR/NULLIF(TOTALWORK,0)*100, 1) AS PCT_DONE,
    ELAPSED_SECONDS,
    TIME_REMAINING AS REMAIN_SEC,
    SQL_ID
FROM V$SESSION_LONGOPS
WHERE (SOFAR < TOTALWORK OR TIME_REMAINING > 0)
  AND START_TIME > SYSDATE - 1
ORDER BY START_TIME DESC;

-- ============================================================
-- 5. SESSIONS EN ATTENTE I/O
-- ============================================================
PROMPT
PROMPT [5/5] Sessions en attente I/O (goulot etranglement)...
PROMPT ============================================================

SELECT
    s.SID,
    s.SERIAL#,
    s.USERNAME,
    s.EVENT,
    s.WAIT_CLASS,
    s.SECONDS_IN_WAIT AS WAIT_SEC,
    s.SQL_ID,
    SUBSTR(s.PROGRAM, 1, 30) AS PROGRAM,
    SUBSTR(s.MACHINE, 1, 20) AS MACHINE
FROM V$SESSION s
WHERE s.WAIT_CLASS IN ('User I/O', 'System I/O')
  AND s.USERNAME IS NOT NULL
ORDER BY s.SECONDS_IN_WAIT DESC;

-- ============================================================
-- RESUME
-- ============================================================
PROMPT
PROMPT ============================================================
PROMPT INTERPRETATION
PROMPT ============================================================
PROMPT
PROMPT Control-M lance un script shell qui execute sqlplus.
PROMPT Le batch apparait comme une SESSION Oracle normale.
PROMPT
PROMPT Chercher dans [1/5] ou [2/5] :
PROMPT   - PROGRAM = 'sqlplus@serveur' ou similaire
PROMPT   - USERNAME = compte applicatif (RNAPPL, etc.)
PROMPT   - SQL_ID correspondant a PKG_RNADEXTAUTO01
PROMPT
PROMPT Si EVENT = 'db file sequential read' ou 'db file scattered read'
PROMPT   => Le batch lit des donnees sur disque (I/O bottleneck confirme)
PROMPT
PROMPT Pour voir la requete complete d'un SQL_ID :
PROMPT   SELECT SQL_FULLTEXT FROM V$SQL WHERE SQL_ID = 'xxx';
PROMPT
PROMPT Pour KILLER le batch (si necessaire) :
PROMPT   ALTER SYSTEM KILL SESSION 'SID,SERIAL#' IMMEDIATE;
PROMPT
PROMPT ============================================================
