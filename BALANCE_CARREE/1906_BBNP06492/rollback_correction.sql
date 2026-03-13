-- =====================================================
-- rollback_correction.sql
-- Compte : 1906 (BBNP06492-EUR)
-- But    : Annuler la correction et revenir a l'etat initial
-- =====================================================
--
-- A UTILISER SI :
-- - La correction a cause des problemes
-- - On veut revenir a l'etat avant correction
--
-- Connexion : sesu - oracle
-- Commande  : sqlplus -S / as sysdba @/home/oracle/BALANCE_CARRE_ECART/1906_BBNP06492/rollback_correction.sql
-- =====================================================

SET ECHO ON
SET FEEDBACK ON
SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON
SET LINESIZE 200
SET PAGESIZE 50

WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;

PROMPT =====================================================
PROMPT ROLLBACK CORRECTION - Compte 1906
PROMPT =====================================================
SELECT SYSDATE, USER FROM DUAL;

-- =====================================================
-- ETAPE 1 : VERIFICATION ETAT ACTUEL
-- =====================================================
PROMPT
PROMPT ===== ETAT ACTUEL =====

SELECT PERIOD_JC, ACCT_ID, BAL_ST, DIFF
FROM BANKREC.BRD_EU_JC_SUMMARY
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';

-- =====================================================
-- ETAPE 2 : ROLLBACK BAL_ST + DIFF
-- =====================================================
PROMPT
PROMPT ===== ROLLBACK BAL_ST + DIFF : Retour a 5,21 et 2,66 =====

UPDATE BANKREC.BRD_EU_JC_SUMMARY
SET BAL_ST = 5.21,
    DIFF = 2.66
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';

COMMIT;

-- =====================================================
-- ETAPE 3 : VERIFICATION APRES ROLLBACK
-- =====================================================
PROMPT
PROMPT ===== ETAT APRES ROLLBACK =====

SELECT PERIOD_JC, ACCT_ID, BAL_ST, DIFF
FROM BANKREC.BRD_EU_JC_SUMMARY
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';

PROMPT
PROMPT *** ROLLBACK TERMINE ***
PROMPT BAL_ST devrait etre 5,21 et DIFF devrait etre 2,66
PROMPT

EXIT SUCCESS;
