create or replace PACKAGE BODY pkg_br_reconciliation_signoff AS
   /****************************************************************************
   Name:    pr_signoff
   Date:    15-Mar-2006
   Author:  S.Mace
   Purpose: This procedure copies outstanding br_data records for an account
            into the br_signoff_trans table in preparation for signoff.

   Change History
   --------------
   Date     Author              Description of change
   ----     ------              ---------------------
   3-5-2006 SMace         Added new procedure pr_signoff_rb and amended existing
                          parameter datatypes to be INTEGER instead of NUMBER.
   16-5-2006 SMace        Modified procedure pr_purge_signoff.

    *****************************************************************************/
   PROCEDURE pr_signoff(p_acct_id IN INTEGER
                    ,p_audit_id IN INTEGER
                    ,p_success OUT INTEGER
                    ) IS

    v_result_str VARCHAR2(255);
    v_msg_str VARCHAR2(255);
    v_output INTEGER;

   BEGIN
     p_success := 0;

     INSERT INTO br_signoff_trans
       (acct_id
       ,audit_id
       ,record_id)
       SELECT bd.acct_id
             ,p_audit_id
             ,bd.record_id
       FROM   br_data bd
       WHERE bd.acct_id = p_acct_id
         AND bd.state = 3;

     COMMIT;
     p_success := 1;

   EXCEPTION
      WHEN OTHERS THEN
      ROLLBACK;
      v_msg_str := 'Error in procedure pkg_br_reconciliation_signoff.pr_signoff.';
      v_result_str := 'Server Error '||to_char(SQLCODE)||' '||SQLERRM;
      pkg_bs_log_event.pr_log_error (
         p_instance_id => 0
        ,p_severity_id => 0
        ,p_program_id => 2
        ,p_acct_id => p_acct_id
        ,p_message => v_msg_str
        ,p_extra_text => v_result_str
        ,p_category_id => 1
        ,p_success => v_output
        );

   END pr_signoff;

   /****************************************************************************
       Name:    pr_purge_signoff
       Date:    15-Mar-2006
       Author:  S.Mace
       Purpose: This procedure deletes rows from the br_signoff_trans for an
                account. It is called as part of the text purge routine. The
                rows to be deleted will be limited by the audit id passed as
                as a parameter. The number of rows to be deleted per transaction
                within the procedure is indicated by the purge blocksize
                parameter (this same value will be used throughout the text
                purge routine).

       Change History
       --------------
       Date     Author              Description of change
       ----     ------              ---------------------
       16-5-06  S.Mace     Changed predicate from 'audit_id <= p_audit_id' to
                           'audit_id < p_audit_id'.
       20-08-07 S.Mace     Replaced p_MaxAuditId with g_sequence_num as part of the AS_ID's work in 2.12.1
   ******************************************************************************/
   PROCEDURE pr_purge_signoff(p_acct_id IN INTEGER
                             ,p_sequence_num IN INTEGER
                             ,p_purge_blocksize IN INTEGER
                             ,p_timestamp     IN VARCHAR
                             ,p_version         IN VARCHAR
                             ,p_deleteReturnsRows IN INTEGER := 0
                             ,p_purgeFilesDir   IN VARCHAR
                             ,p_success OUT INTEGER)
  IS

  v_result_str    VARCHAR2(255);
  v_msg_str       VARCHAR2(255);
  v_output        INTEGER;
  file_id1        UTL_FILE.FILE_TYPE;
  l_str           varchar2(5000);
  l_acct_name     varchar2(255);
  v_file_name     VARCHAR2(255) := p_timestamp||'_'||to_char(p_acct_id)||'_'||'br_signoff_trans.txt';

  type v_data_recs1 is table of br_signoff_trans.acct_id%TYPE;
  type v_data_recs2 is table of br_signoff_trans.audit_id%TYPE;
  type v_data_recs3 is table of br_signoff_trans.record_id%TYPE;
  l_data_recs1 v_data_recs1;
  l_data_recs2 v_data_recs2;
  l_data_recs3 v_data_recs3;

  BEGIN
    p_success := 0;

    if p_deleteReturnsRows = 1 then

      file_id1 := utl_file.fopen(p_PurgeFilesDir,v_file_name,'a',32767);

      select acct_name
      into l_acct_name
      from bs_accts
      where acct_id = p_acct_id;

      l_str := p_timestamp||chr(127)||'br_signoff_trans'||chr(127)||p_version||chr(127)||to_char(p_acct_id)||chr(127)||l_acct_name;

      utl_file.put_line(file_id1, l_str);

      l_str := 'ACCT_ID'||chr(127)||'AUDIT_ID'||chr(127)||'RECORD_ID';

      utl_file.put_line(file_id1, l_str);

    end if;


    LOOP
      --      DELETE FROM br_signoff_trans
      --        WHERE acct_id = p_acct_id
      --          AND audit_id < p_audit_id
      --          AND rownum <= p_purge_blocksize;


     --EXECUTE IMMEDIATE 'DELETE FROM br_signoff_trans
     --   WHERE acct_id = :1
     --    AND audit_id < :2 --p_audit_id
     --    AND rownum <= :3 --p_purge_blocksize;
     --  returning ACCT_ID,AUDIT_ID,RECORD_ID
     --  INTO :4,:5,:6 '
     -- USING p_acct_Id,g_sequence_num,p_purge_blocksize RETURNING BULK COLLECT INTO
     -- l_data_recs1,
     -- l_data_recs2,
     -- l_data_recs3;

     EXECUTE IMMEDIATE 'DELETE FROM br_signoff_trans bst
                        WHERE EXISTS (SELECT 1
                                      FROM br_signoff_trans bst2,
                                           br_audit bra
                                      WHERE bst2.acct_id = :1                --p_acct_id
                                      AND bra.acct_id = bst.acct_id
                                      AND bra.audit_id = bst.audit_id
                                      AND bra.sequence_num < :2              --p_sequence_num
                                      AND bra.record_id = bst.record_id
                                      )
                                      AND rownum <= :3                       --p_purge_blocksize
                                      RETURNING acct_id,audit_id,record_id
                                      INTO :4,:5,:6 '
                         USING p_acct_Id,p_sequence_num,p_purge_blocksize RETURNING BULK COLLECT INTO
                         l_data_recs1,
                         l_data_recs2,
                         l_data_recs3;



    if l_data_recs1.COUNT > 0 then

      if p_deleteReturnsRows = 1 then


        for indx in l_data_recs1.FIRST .. l_data_recs1.LAST
         loop
           l_str := to_char(l_data_recs1(indx))||chr(127)||
                    to_char(l_data_recs2(indx))||chr(127)||
                    to_char(l_data_recs3(indx));
           pkg_br_purge.replace_tab_cr_line_feed(l_str);

           utl_file.put_line(file_id1, l_str);

         end loop;

        end if; -- if p_deleteReturnsRows = 1 then

      end if;
     EXIT WHEN SQL%NOTFOUND;
     COMMIT;
     END LOOP;

     COMMIT;
     p_success := 1;

    EXCEPTION
       WHEN OTHERS THEN
       ROLLBACK;
       v_msg_str := 'Error in procedure pkg_br_reconciliation_signoff.pr_purge_signoff.';
       v_result_str := 'Server Error '||to_char(SQLCODE)||' '||SQLERRM;
       pkg_bs_log_event.pr_log_error (
          p_instance_id => 0
         ,p_severity_id => 0
         ,p_program_id => 2
         ,p_acct_id => p_acct_id
         ,p_message => v_msg_str
         ,p_extra_text => v_result_str
         ,p_category_id => 1
         ,p_success => v_output
         );

    END pr_purge_signoff;

    /****************************************************************************
        Name:    pr_signoff_rb
        Date:    03-May-2006
        Author:  S.Mace
        Purpose: This procedure deletes rows from the br_signoff_trans for an
                 account. The rows to be deleted will be identified by the audit id
                 passed as as a parameter.

        Change History
        --------------
        Date     Author              Description of change
        ----     ------              ---------------------
    ******************************************************************************/
    PROCEDURE pr_signoff_rb(p_acct_id IN INTEGER
                           ,p_audit_id IN INTEGER
                           ,p_success OUT INTEGER
                           ) IS

    v_result_str VARCHAR2(255);
    v_msg_str VARCHAR2(255);
    v_output INTEGER;

   BEGIN
     p_success := 0;

     DELETE FROM br_signoff_trans
     WHERE acct_id = p_acct_id
     AND audit_id = p_audit_id;

     COMMIT;

     p_success := 1;

    EXCEPTION
       WHEN OTHERS THEN
       ROLLBACK;
       v_msg_str := 'Error in procedure pkg_br_reconciliation_signoff.pr_signoff_rb.';
       v_result_str := 'Server Error '||to_char(SQLCODE)||' '||SQLERRM;
       pkg_bs_log_event.pr_log_error (
          p_instance_id => 0
         ,p_severity_id => 0
         ,p_program_id => 2
         ,p_acct_id => p_acct_id
         ,p_message => v_msg_str
         ,p_extra_text => v_result_str
         ,p_category_id => 1
         ,p_success => v_output
         );

    END pr_signoff_rb;

END pkg_br_reconciliation_signoff;