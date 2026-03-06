create or replace package body pkg_br_purge
as

    CA_CYCLE_ASSIGN         constant pls_integer := 19;
    CA_CYCLE_ASSIGN_REJECT  constant pls_integer := 20;
    CA_CYCLE_ASSIGN_RESET   constant pls_integer := 21;

  DEBUG_ON constant boolean := false;

  procedure log_debug(p_message varchar2, p_extra_text varchar2 := null)
  is
    v_success pls_integer;
  begin

    if (DEBUG_ON) then

        pkg_bs_log_event.pr_log_error(
                p_instance_id => -99
               ,p_severity_id => 0
               ,p_message => p_message
               ,p_extra_text => p_extra_text
               ,p_category_id => 1
               ,p_success => v_success);

    end if;

  end log_debug;
 /****************************************************************************
   Name:    pr_lookup_sequence_number
   Date:    20-Aug-2007
   Author:  S.Mace
   Purpose: This procedure looks up the sequence number associated
            with an audit record for an account and stores it in a a global variable.
            The sequence number is used as the "cut-off point" for which all earlier account records
            are to be purged. Introduced as part of the as_ids changes in 2.12.1.

   Change History

   --------------
   Date     Author              Description of change
   ----     ------              ---------------------

  *****************************************************************************/

  PROCEDURE pr_lookup_sequence_number(p_acctId         IN INTEGER := 0
                                     ,p_eventLogTiming IN INTEGER
                                     ,p_maxAuditId     IN INTEGER := 0
                                     ,p_success        OUT INTEGER
                                     ,p_errReason      OUT VARCHAR2
                                     )
  IS

    v_startTime           DATE;
    v_endTime             DATE;
    v_timeDiff            INTEGER := 0;
    v_success             INTEGER := 0; -- defaulted to failure
    e_invalid_id          EXCEPTION;

  BEGIN

    IF p_eventLogTiming = 1
    THEN
      v_startTime := sysdate;
    END IF;

    g_maxAuditId := p_maxAuditId;               -- keep this value globally in case needed elsewhere
    g_sequence_num := NULL;                     -- keep this globally rather than passing around as a parameter

    begin
        select bra.sequence_num
          into g_sequence_num
          from br_audit bra
         where bra.acct_id = p_acctid
           and bra.audit_id = g_maxauditid;
    exception
        when no_data_found then
           raise e_invalid_id;
    end;

    IF p_eventLogTiming = 1 THEN
       v_endTime := sysdate;
       v_timeDiff := (v_endTime - v_startTime) * 86400;  -- time given in seconds
       Pkg_Bs_Log_Event.pr_log_timing(p_instance_id => 0
                                     ,p_program_id => 11
                                     ,p_message => 'Sequence number lookup up'
                                     ,p_extra_text => 'Duration: '||to_char(v_timeDiff)||' seconds'
                                     ,p_category_id => 1
                                     ,p_success => v_success);
    END IF;

    v_success := 1;
    p_success := v_success;

  EXCEPTION
  WHEN e_invalid_id
  THEN
    p_errReason := 'Error calling pkg_br_purge.pr_lookup_sequence_number - no sequence num';

    Pkg_Bs_Log_Event.pr_log_error (p_instance_id => 0
                                  ,p_severity_id => 0
                                  ,p_message => 'Error calling pkg_br_purge.pr_lookup_sequence_number'
                                  ,p_extra_text => 'Unable to retrieve valid sequence number for audit id'
                                  ,p_category_id => 1
                                  ,p_success => v_success
                                  );

    p_success := 0;  -- calling program needs to know exception raised


  WHEN OTHERS THEN

    p_errReason := 'Error calling pkg_br_purge.pr_lookup_sequence_number';

    pkg_bs_log_event.pr_log_error (p_instance_id => 0
                                  ,p_severity_id => 0
                                  ,p_message => 'Error calling pkg_br_purge.pr_lookup_sequence_number'
                                  ,p_extra_text => 'Server Error '||to_char(SQLCODE)||' '||SQLERRM
                                  ,p_category_id => 1
                                  ,p_success => v_success
                                  );

    p_success := 0;  -- calling program needs to know exception raised

  END pr_lookup_sequence_number;


  /****************************************************************************
   Name:    replace_tab_cr_line_feed
   Date:    8-Mar-2007
   Author:  P.Fulay
   Purpose: This procedure replaces carriage return with chr(252)
                                    new-line with chr(253)
                                    tab with chr(254)

   Change History
   --------------
   Date     Author              Description of change
   ----     ------              ---------------------
  *****************************************************************************/

  PROCEDURE replace_tab_cr_line_feed(v_str IN OUT VARCHAR2) IS
  BEGIN
    WHILE (instr(v_str,chr(9)) > 0)
      LOOP
        v_str := (substr(v_str,1,instr(v_str,chr(9))-1)||chr(254)||
              substr(v_str,instr(v_str,chr(9))+1));
      END LOOP;

    WHILE (instr(v_str,chr(13)) > 0)
      LOOP
        v_str := (substr(v_str,1,instr(v_str,chr(13))-1)||chr(253)||
              substr(v_str,instr(v_str,chr(13))+1));
      END LOOP;

    WHILE (instr(v_str,chr(10)) > 0)
      LOOP
        v_str := (substr(v_str,1,instr(v_str,chr(10))-1)||chr(252)||
              substr(v_str,instr(v_str,chr(10))+1));
      END LOOP;

  END replace_tab_cr_line_feed;


  procedure pr_truncate_temp_table(p_tempTableName in varchar2
                                  ,p_eventLogTiming in integer
                                  ,p_success out integer
                                  ,p_errReason out varchar2
                                  )
 /****************************************************************************
   Name:    pr_truncate_temp_table
   Purpose: This procedure truncates data from the specified table.
            Note that truncate causes a commit;
            The activity may optionally be timed and the result put into the
            bs_event_log table.

  *****************************************************************************/
  is
      v_success             integer := 0; -- defaulted to failure
      v_cursor_name         integer;
      v_rows_processed      integer;
      v_timeDiff            integer := 0;
      v_startTime           date;
      v_endTime             date;
  begin

    if p_eventLogTiming = 1
    then
      v_startTime := sysdate;
    end if;

    execute immediate 'truncate table ' || p_tempTableName;

    if p_eventLogTiming = 1
    then
      v_endTime := sysdate;
      v_timeDiff := (v_endTime - v_startTime) * 86400;  -- time given in seconds

      Pkg_Bs_Log_Event.pr_log_timing(p_instance_id => 0
                                    ,p_program_id => 11
                                    ,p_message => 'Temporary table '||p_tempTableName||' truncated. '
                                    ,p_extra_text => 'Duration: '||to_char(v_timeDiff)||' seconds'
                                    ,p_category_id => 1
                                    ,p_success => v_success);

     end if;

     v_success := 1;
     p_success := v_success;

  exception
    when others then
      p_errReason := 'pr_truncate_table';

      Pkg_Bs_Log_Event.pr_log_error (p_instance_id => 0
                                    ,p_severity_id => 0
                                    ,p_message => 'Error calling pkg_br_purge.pr_truncate_temp_table'
                                    ,p_extra_text => 'Server Error '||to_char(sqlcode)||' '||sqlerrm
                                    ,p_category_id => 1
                                    ,p_success => v_success
                                    );
      p_success := 0;                  -- calling program needs to know exception raised

  end pr_truncate_temp_table;


  procedure pr_populate_temp_table(p_tempTableName      in varchar2
                                  ,p_acctId             in integer := 0
                                  ,p_eventLogTiming     in integer := 0
                                  ,p_success            out integer
                                  ,p_errReason          out varchar2
                                  )
  is
  /****************************************************************************
   Name:    pr_populate_temp_table
   Purpose: This procedure populates the specified table with br_data records for
            an account that is required to be deleted during a text purge run. The
      range of data to be deleted is delimited by parameters passed to this
      procedure. The data is held temporarily as a driving table for deletions
      handled by other procedures.
           The activity may optionally be timed and the result put into the bs_event_log table.
  *****************************************************************************/

  v_sql_stmt       VARCHAR2(2000);
  v_timeDiff       INTEGER := 0;
  v_success        INTEGER := 0; -- defaulted to failure
  v_cursor_name    INTEGER;
  v_rows_processed INTEGER;
  v_stop_now       INTEGER;
  v_startTime      DATE;
  v_endTime        DATE;
  v_min_record_id  INTEGER;
  v_max_record_id  INTEGER;
  v_acct_type      INTEGER ;


  BEGIN

    IF p_eventLogTiming = 1
    THEN
      v_startTime := sysdate;
    END IF;
    --
    -- Populate data temporary table with records to be processed during text purge
    --

    begin
      select bsa.acct_type
      into v_acct_type
      from bs_accts bsa
      where bsa.acct_id = p_acctid;
    end;


    IF v_acct_type = 2
    THEN
        insert into tempacc
        (select acct_id
              ,record_id
              ,orig_id
              ,note_group
              ,rowid
        from (select brd.acct_id
                    ,brd.record_id
                    ,brd.orig_id
                    ,brd.note_group
                    ,brd.rowid
                    ,max(case brd.state
                         when 4 then 4
                         when 6 then 6
                         else 0 end) over (partition by brd.acct_id, brd.orig_id) max_state
                    ,brd.cs_flag
              from br_data brd
                  ,br_audit bra
              where brd.acct_id = p_acctid
              and brd.acct_id = bra.acct_id
              and brd.lastaudit = bra.audit_id
              and bra.sequence_num <= g_sequence_num)
        where max_state in (4,6) or cs_flag in ('R','B')
        );  /*Holdings*/

    ELSE
        insert into tempacc
        (select acct_id
              ,record_id
              ,orig_id
              ,note_group
              ,rowid
        from (select brd.acct_id
                    ,brd.record_id
                    ,brd.orig_id
                    ,brd.note_group
                    ,brd.rowid
                    ,max(case brd.state
                         when 4 then 4
                         when 6 then 6
                         else 0 end) over (partition by brd.acct_id, brd.orig_id) max_state
              from br_data brd
                  ,br_audit bra
              where brd.acct_id = p_acctid
              and brd.acct_id = bra.acct_id
              and brd.lastaudit = bra.audit_id
              and bra.sequence_num <= g_sequence_num)
        where max_state in (4,6)
        ); /* reconciled, deleted */

    END IF;

    commit;

    -- Get the minimum and maximum record id, orig_id
    -- br_audit_cycle_assign has no record_id, and br_audit.record_id is not populated for
    -- cycle assignment audit, the orig_id is required for chunking for purging this
    -- Do not use dynamic sql, as the temporary table tempacc uses no other name:

    begin
        select  min(record_id), max(record_id), min(orig_id), max(orig_id)
        into g_min_record_id, g_max_record_id, g_min_orig_id, g_max_orig_id
        from tempacc;
    exception
        when others then
            raise;
    end;

    if p_eventlogtiming = 1
    then
      v_endtime := sysdate;
      v_timeDiff := (v_endTime - v_startTime) * 86400;  -- time given in seconds

      Pkg_Bs_Log_Event.pr_log_timing(p_instance_id => 0
                                    ,p_program_id => 11
                                    ,p_message => 'Temporary table '||p_tempTableName||' populated for account id '||to_char(p_acctId)||' max audit id '||to_char(g_maxAuditId)||', '||to_char(v_rows_processed)||' rows inserted.'
                                    ,p_extra_text => 'Duration: '||to_char(v_timeDiff)||' seconds'
                                    ,p_category_id => 1
                                    ,p_success => v_success);
    end if;

    v_success := 1;

    p_success := v_success;

    exception
    when others then

      p_errReason := 'pr_populate_temp_table';
      pkg_bs_log_event.pr_log_error (p_instance_id => 0
                                    ,p_severity_id => 0
                                    ,p_message => 'Error calling pkg_br_purge.pr_populate_temp_table'
                                    ,p_extra_text => 'Server Error '||to_char(SQLCODE)||' '||SQLERRM
                                    ,p_category_id => 1
                                    ,p_success => v_success
                                    );
      p_success := 0;              -- error returned, exception not re-raised as caller does not handle exceptions

  END pr_populate_temp_table;

  /****************************************************************************

   Name:    pr_purge_audit_records
   Date:    28-Mar-2006
   Author:  S.Mace
   Purpose: This procedure is part of the text purge routine and deletes the audit
            records associated with the br_data rows held in the specified temporary
      table. The deletion is managed by deleting a set number of records at a
      time in a loop - this is to avoid the job failing for a high number of
      deletions when extents may otherwise be blown.

            The activity may optionally be timed and the result put into the bs_event_log table.

   Change History
   --------------

   Date     Author              Description of change
   ----     ------              ---------------------
   20-08-07 S.Mace              Removed p_maxAuditId as unused.
   05-09-07 S.Perrett           Changed delete returning output to file, to a select returning output
                                to file ordered by sequence_num, then added extra delete statement (this
                                was done as delete can't rpoduce ordered output)
  *****************************************************************************/

  PROCEDURE pr_purge_audit_records(p_tempTableName     IN VARCHAR2
                                  ,p_acctId            IN INTEGER := 0
                                  ,p_eventLogTiming    IN INTEGER := 0
                                  ,p_purgeBlockSize    IN INTEGER := 0
                                  ,p_timestamp         IN VARCHAR2
                                  ,p_version           IN VARCHAR2
                                  ,p_deleteReturnsRows IN INTEGER := 0
                                  ,p_purgeFilesDir     IN VARCHAR2
                                  ,p_success           OUT INTEGER
                                  ,p_errReason         OUT VARCHAR2
								  ,p_min_orphan_rec_id OUT INTEGER
                                  ,p_max_orphan_rec_id OUT INTEGER
                                  )
  IS

  v_timeDiff            INTEGER := 0;
  v_success             INTEGER := 0; -- defaulted to failure
  v_begRecordRange      INTEGER := 0;
  v_endRecordRange      INTEGER := 0;
  v_cursor_name         INTEGER;
  v_rows_processed      INTEGER;
  v_tot_rows_processed  INTEGER := 0;
  v_startTime           DATE;
  v_endTime             DATE;
  file_id1              UTL_FILE.FILE_TYPE;
  l_str                 VARCHAR2(5000);
  l_acct_name            VARCHAR2(255);
  v_file_name           VARCHAR2(40) := p_timestamp||'_'||to_char(p_acctid)||'_'||'br_audit.txt';

  TYPE v_data_recs1 IS TABLE OF BR_AUDIT.acct_id%TYPE;
  TYPE v_data_recs2 IS TABLE OF BR_AUDIT.audit_id%TYPE;
  TYPE v_data_recs3 IS TABLE OF BR_AUDIT.TYPE%TYPE;
  TYPE v_data_recs4 IS TABLE OF BR_AUDIT.TIMESTAMP%TYPE;
  TYPE v_data_recs5 IS TABLE OF BR_AUDIT.cs_flag%TYPE;
  TYPE v_data_recs6 IS TABLE OF BR_AUDIT.record_id%TYPE;
  TYPE v_data_recs7 IS TABLE OF BR_AUDIT.user_id%TYPE;
  TYPE v_data_recs8 IS TABLE OF BR_AUDIT.bfr_state%TYPE;
  TYPE v_data_recs9 IS TABLE OF BR_AUDIT.aft_state%TYPE;
  TYPE v_data_recs10 IS TABLE OF BR_AUDIT.note_id%TYPE;
  TYPE v_data_recs11 IS TABLE OF BR_AUDIT.orig_id%TYPE;
  TYPE v_data_recs12 IS TABLE OF BR_AUDIT.bfr_date%TYPE;
  TYPE v_data_recs13 IS TABLE OF BR_AUDIT.aft_date%TYPE;
  TYPE v_data_recs14 IS TABLE OF BR_AUDIT.whichone%TYPE;
  TYPE v_data_recs15 IS TABLE OF BR_AUDIT.recmethod%TYPE;
  TYPE v_data_recs16 IS TABLE OF BR_AUDIT.bfr_amt%TYPE;
  TYPE v_data_recs17 IS TABLE OF BR_AUDIT.aft_amt%TYPE;
  TYPE v_data_recs18 IS TABLE OF BR_AUDIT.num_in_grp%TYPE;
  TYPE v_data_recs19 IS TABLE OF BR_AUDIT.pass_id%TYPE;
  TYPE v_data_recs20 IS TABLE OF BR_AUDIT.spare_one%TYPE;
  TYPE v_data_recs21 IS TABLE OF BR_AUDIT.spare_two%TYPE;
  TYPE v_data_recs22 IS TABLE OF BR_AUDIT.sequence_num%TYPE;
  TYPE v_data_recs23 IS TABLE OF BR_AUDIT.ATTACHMENT_ID%TYPE;

  l_data_recs1 v_data_recs1;
  l_data_recs2 v_data_recs2;
  l_data_recs3 v_data_recs3;
  l_data_recs4 v_data_recs4;
  l_data_recs5 v_data_recs5;
  l_data_recs6 v_data_recs6;
  l_data_recs7 v_data_recs7;
  l_data_recs8 v_data_recs8;
  l_data_recs9 v_data_recs9;
  l_data_recs10 v_data_recs10;
  l_data_recs11 v_data_recs11;
  l_data_recs12 v_data_recs12;
  l_data_recs13 v_data_recs13;
  l_data_recs14 v_data_recs14;
  l_data_recs15 v_data_recs15;
  l_data_recs16 v_data_recs16;
  l_data_recs17 v_data_recs17;
  l_data_recs18 v_data_recs18;
  l_data_recs19 v_data_recs19;
  l_data_recs20 v_data_recs20;
  l_data_recs21 v_data_recs21;
  l_data_recs22 v_data_recs22;
  l_data_recs23 v_data_recs23;

  BEGIN


    IF p_eventLogTiming = 1
    THEN
      v_startTime := sysdate;
    END IF;

    --
    -- This loop is to control the number of br_audit records processed per loop to avoid extents being blown
    --
    -- Set the range of records to be processed
    --
    v_begRecordRange := g_min_record_id;
    v_endRecordRange := g_min_record_id + p_purgeBlockSize;

	p_min_orphan_rec_id := v_begRecordRange;
	p_max_orphan_rec_id := v_endRecordRange;

    --
    IF p_deleteReturnsRows = 1 THEN
      file_id1 := UTL_FILE.FOPEN(p_PurgeFilesDir,v_file_name,'a',32767);

      SELECT acct_name
      INTO l_acct_name
      FROM BS_ACCTS
      WHERE acct_id = p_acctid;

      -- Since the C++ code will also write part of the br_audit file, the header and column records should not be
      -- written by the stored procedure.

      --l_str := p_timestamp||chr(127)||'br_audit'||chr(127)||p_version||chr(127)||to_char(p_acctid)||chr(127)||l_acct_name;
      --   utl_file.put_line(file_id1, l_str);

      --l_str := 'ACCT_ID'||chr(127)||'AUDIT_ID'||chr(127)||'TYPE'||chr(127)||'TIMESTAMP'||chr(127)||'CS_FLAG'||chr(127)||
      --'RECORD_ID'||chr(127)||'USER_ID'||chr(127)||'BFR_STATE'||chr(127)||'AFT_STATE'||chr(127)||
      --'NOTE_ID'||chr(127)||'ORIG_ID'||chr(127)||'BFR_DATE'||chr(127)||'AFT_DATE'||chr(127)||'WHICHONE'||chr(127)||
      --'RECMETHOD'||chr(127)||'BFR_AMT'||chr(127)||'AFT_AMT'||chr(127)||'NUM_IN_GRP'||chr(127)||'PASS_ID'||chr(127)||
      --'SPARE_ONE'||chr(127)||'SPARE_TWO';

      --   utl_file.put_line(file_id1, l_str);

    END IF;

    WHILE (v_begRecordRange <= g_max_record_id)
    LOOP

      EXECUTE IMMEDIATE 'SELECT * FROM br_audit bra '||
                    'where bra.acct_id = :1 '||
                    'AND   bra.record_id BETWEEN :2 and :3  '||
                    'AND exists (select ''x'' from '||p_tempTableName||
                    '            where acct_id = bra.acct_id '||
                    '          and record_id = bra.record_id) '||
                    'AND (bra.type = 0 OR bra.type = 2 OR bra.type = 4 OR bra.type = 6 ) order by bra.sequence_num '
       BULK COLLECT INTO l_data_recs1,
                                  l_data_recs2,
                                  l_data_recs3,
                                  l_data_recs4,
                                  l_data_recs5,
                                  l_data_recs6,
                                  l_data_recs7,
                                  l_data_recs8,
                                  l_data_recs9,
                                  l_data_recs10,
                                  l_data_recs11,
                                  l_data_recs12,
                                  l_data_recs13,
                                  l_data_recs14,
                                  l_data_recs15,
                                  l_data_recs16,
                                  l_data_recs17,
                                  l_data_recs18,
                                  l_data_recs19,
                                  l_data_recs20,
                                  l_data_recs21,
                                  l_data_recs22,
								  l_data_recs23
    using p_acctId,v_begRecordRange,v_endRecordRange                                   ;

      IF l_data_recs1.count > 0 THEN
        v_tot_rows_processed := v_tot_rows_processed + l_data_recs1.count;

        IF p_deleteReturnsRows = 1 THEN
          FOR indx IN l_data_recs1.first .. l_data_recs1.last
          LOOP
            l_str := to_char(l_data_recs1(indx))||chr(127)||
                     to_char(l_data_recs2(indx))||chr(127)||
                     to_char(l_data_recs3(indx))||chr(127)||
                     to_char(l_data_recs4(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                     l_data_recs5(indx)||chr(127)||
                     to_char(l_data_recs6(indx))||chr(127)||
                     to_char(l_data_recs7(indx))||chr(127)||
                     to_char(l_data_recs8(indx))||chr(127)||
                     to_char(l_data_recs9(indx))||chr(127)||
                     to_char(l_data_recs10(indx))||chr(127)||
                     to_char(l_data_recs11(indx))||chr(127)||
                     to_char(l_data_recs12(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                     to_char(l_data_recs13(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                     to_char(l_data_recs14(indx))||chr(127)||
                     to_char(l_data_recs15(indx))||chr(127)||
                     to_char(l_data_recs16(indx))||chr(127)||
                     to_char(l_data_recs17(indx))||chr(127)||
                     to_char(l_data_recs18(indx))||chr(127)||
                     to_char(l_data_recs19(indx))||chr(127)||
                     to_char(l_data_recs21(indx))||chr(127)||
                     to_char(l_data_recs23(indx));
            -- NOT OUTPUTING SEQUENCE_NUM    TO_CHAR(l_data_recs22(indx));

            -- replace carriage return with chr(252)
            --   new-line with chr(253)
            --   tab with chr(254)

            replace_tab_cr_line_feed(l_str);

            UTL_FILE.PUT_LINE(file_id1, l_str);

          END LOOP;

        END IF; -- if p_deleteReturnsRows = 1 then

      END IF;

      EXECUTE IMMEDIATE 'DELETE FROM br_audit bra '||
                    'where bra.acct_id = :1 '||
                    'AND   bra.record_id BETWEEN :2 and :3  '||
                    'AND exists (select ''x'' from '||p_tempTableName||
                    '            where acct_id = bra.acct_id '||
                    '          and record_id = bra.record_id) '||
                    'AND (bra.type = 0 OR bra.type = 2 OR bra.type = 4 OR bra.type = 6 OR bra.type = 23) '
                          using p_acctId,v_begRecordRange,v_endRecordRange ;

      COMMIT;
      --
      -- increment the variables for the record range to be processed in the next loop
      --
	  p_max_orphan_rec_id := v_endRecordRange;
      v_begRecordRange := v_endRecordRange + 1;
      v_endRecordRange := v_endRecordRange + p_purgeBlockSize;

    END LOOP;

    IF p_deleteReturnsRows = 1 THEN
      UTL_FILE.FCLOSE(file_id1);
      file_id1.ID := NULL;
    END IF;

    IF p_eventLogTiming = 1 THEN
      v_endTime := sysdate;
      v_timeDiff := (v_endTime - v_startTime) * 86400;  -- time given in seconds
      Pkg_Bs_Log_Event.pr_log_timing(p_instance_id => 0
                                    ,p_program_id => 11
                                    ,p_message => 'Audit records purged '||to_char(v_tot_rows_processed)||' rows deleted.'
                                    ,p_extra_text => 'Duration: '||to_char(v_timeDiff)||' seconds'
                                    ,p_category_id => 1
                                    ,p_success => v_success);
    END IF;

    v_success := 1;
    p_success := v_success;

    EXCEPTION
    WHEN OTHERS THEN
      IF p_deleteReturnsRows = 1 THEN
         UTL_FILE.FCLOSE(file_id1);
         file_id1.ID := NULL;
      END IF;
      p_errReason := 'pr_purge_audit_records';
      Pkg_Bs_Log_Event.pr_log_error (p_instance_id => 0
                                    ,p_severity_id => 0
                                    ,p_message => 'Error calling pkg_br_purge.pr_purge_audit_records'
                                    ,p_extra_text => 'Server Error '||to_char(SQLCODE)||' '||SQLERRM
                                    ,p_category_id => 1
                                    ,p_success => v_success
                                    );

      p_success := 0;  -- calling program needs to know exception raised

  END pr_purge_audit_records;


procedure pr_purge_ca_audit_records(p_tempTableName    in varchar2
                                  ,p_acctId            in integer := 0
                                  ,p_eventLogTiming    in integer := 0
                                  ,p_purgeBlockSize    in integer := 0
                                  ,p_timestamp         in varchar2
                                  ,p_version           in varchar2
                                  ,p_deleteReturnsRows in integer := 0
                                  ,p_purgeFilesDir     in varchar2
                                  ,p_success           out integer
                                  ,p_errReason         out varchar2
                                  )
  is
/****************************************************************************
    Name:    pr_purge_ca_audit_records
    Purpose:
    This procedure is part of the text purge routine and deletes the cycle assignment audit
    records and br_audit rows associated with the br_data rows held in the specified temporary
    table, and restricted to these audit types:
    19  CYCLE_ASSIGN    Cycle assignment was performed for this account
    20  CYCLE_ASSIGN_REJECT    Cycle assignment rejection was performed for this account
    21  CYCLE_ASSIGN_RESET (CA "unassign")

    The activity may optionally be timed and the result put into the bs_event_log table.

    Chunking of blocks of rows is by acct_id/orig_id, as record_id is null for these types - this follows
    the principle used by C++.

    Table access:
        br_audit_cycle_assign S, D
        br_audit S, D
        tempacc S

  *****************************************************************************/


  v_timediff            integer := 0;
  v_success             integer := 0; -- defaulted to failure
  v_begrecordrange      integer := 0;
  v_endrecordrange      integer := 0;
  v_cursor_name         integer;
  v_rows_processed      integer;
  v_tot_rows_processed  integer := 0;
  v_endtime             date;
  v_starttime           date;
  file_id_ca_audit      utl_file.file_type;
  file_id_audit         utl_file.file_type;

  l_str                 varchar2(5000);
  l_acct_name           varchar2(255);
  v_audit_file_name     varchar2(255) := p_timestamp||'_'||to_char(p_acctid)||'_'||'br_audit.txt';
  v_audit_cycle_assign_file_name    VARCHAR2(255) := p_timestamp||'_'||to_char(p_acctid)||'_'||'br_audit_cycle_assign.txt';

  type t_br_audit_cycle_assign_rec is table of br_audit_cycle_assign%rowtype index by pls_integer;
  type t_br_audit_rec is table of br_audit%rowtype index by pls_integer;

  v_br_audit_cycle_assign_rec t_br_audit_cycle_assign_rec;
  v_br_audit_rec t_br_audit_rec;

  begin

    if p_eventlogtiming = 1
    then
        v_starttime := sysdate;
    end if;

    if p_deletereturnsrows = 1 then
        file_id_audit     := utl_file.fopen(p_purgefilesdir,v_audit_file_name,'a',32767);
        file_id_ca_audit  := utl_file.fopen(p_purgefilesdir,v_audit_cycle_assign_file_name,'a',32767);

        -- write file and column header for cycle assign audit file (and not for audit file)
        select acct_name
        into l_acct_name
        from bs_accts
        where acct_id = p_acctid;

        l_str := p_timestamp||chr(127)||'br_audit_cycle_assign'||chr(127)||p_version||chr(127)||
                 to_char(p_acctid)||chr(127)||l_acct_name;

        utl_file.put_line(file_id_ca_audit, l_str);

        l_str :=
            'audit_cycle_assign_id'||chr(127)||
            'acct_id'||chr(127)||
            'audit_id'||chr(127)||
            'orig_id';

        utl_file.put_line(file_id_ca_audit, l_str);

    end if;


    --
    -- This loop controls the number of records processed per loop to avoid exceeding undo tablespace limits
    --
    -- Set the range of records to be processed
    --
    v_begRecordRange := g_min_orig_id;
    v_endRecordRange := g_min_orig_id + p_purgeBlockSize;

    while (v_begrecordrange <= g_max_orig_id)
    loop

        -- Delete from br_audit_cycle_assign rows which tempacc identified as candidates for purging.
        -- (not necessary to restrict to audit type 19,20,21 as br_audit_cycle_assign only contains these types)
        delete from br_audit_cycle_assign
                where audit_cycle_assign_id in (
                    select  aca.audit_cycle_assign_id
                    from    br_audit_cycle_assign aca
                    join    tempacc t
                            on aca.acct_id = t.acct_id
                            and aca.orig_id = t.orig_id
                    where   t.acct_id = p_acctId
                    and     t.orig_id between v_begRecordRange and v_endRecordRange)
        returning audit_cycle_assign_id, acct_id, audit_id, orig_id
        bulk collect into v_br_audit_cycle_assign_rec;

        if v_br_audit_cycle_assign_rec.count > 0 then
            v_tot_rows_processed := v_tot_rows_processed + v_br_audit_cycle_assign_rec.count;

             if p_deletereturnsrows = 1 then
              for indx in v_br_audit_cycle_assign_rec.first .. v_br_audit_cycle_assign_rec.last
              loop
                l_str :=
                    to_char(v_br_audit_cycle_assign_rec(indx).audit_cycle_assign_id) || chr(127) ||
                    to_char(v_br_audit_cycle_assign_rec(indx).acct_id) || chr(127) ||
                    to_char(v_br_audit_cycle_assign_rec(indx).audit_id) || chr(127) ||
                    to_char(v_br_audit_cycle_assign_rec(indx).orig_id);

                replace_tab_cr_line_feed(l_str);

                utl_file.put_line(file_id_ca_audit, l_str);
              end loop;
            end if;

        end if;

        -- now delete br_audit rows (for the current account) which have no br_audit_cycle_assign children
        delete from br_audit bra
        where bra.acct_id = p_acctId
        and (bra.type = CA_CYCLE_ASSIGN OR bra.type = CA_CYCLE_ASSIGN_REJECT OR bra.type = CA_CYCLE_ASSIGN_RESET)
        and exists (select 1
            from tempacc
            where acct_id = bra.acct_id
            and   audit_id = bra.audit_id
            and   orig_id between v_begRecordRange and v_endRecordRange
            )
        and not exists ( select 1
                 from   br_audit_cycle_assign baca
                 where  acct_id = p_acctId
                 and baca.audit_id = bra.audit_id )
        returning acct_id, audit_id, type, timestamp, cs_flag, record_id, user_id,
                bfr_state, aft_state, note_id, orig_id, bfr_date, aft_date, whichone,
                recmethod, bfr_amt, aft_amt, num_in_grp, pass_id, spare_one, spare_two,
                sequence_num,attachment_id
        bulk collect into v_br_audit_rec;

        if v_br_audit_rec.count > 0 then
            v_tot_rows_processed := v_tot_rows_processed + v_br_audit_rec.count;

            if p_deletereturnsrows = 1 then
              for indx in v_br_audit_rec.first .. v_br_audit_rec.last
              loop

                l_str := to_char(v_br_audit_rec(indx).acct_id)||chr(127)||
                         to_char(v_br_audit_rec(indx).audit_id)||chr(127)||
                         to_char(v_br_audit_rec(indx).type)||chr(127)||
                         to_char(v_br_audit_rec(indx).timestamp,'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                         v_br_audit_rec(indx).cs_flag||chr(127)||
                         to_char(v_br_audit_rec(indx).record_id)||chr(127)||
                         to_char(v_br_audit_rec(indx).user_id)||chr(127)||
                         to_char(v_br_audit_rec(indx).bfr_state)||chr(127)||
                         to_char(v_br_audit_rec(indx).aft_state)||chr(127)||
                         to_char(v_br_audit_rec(indx).note_id)||chr(127)||
                         to_char(v_br_audit_rec(indx).orig_id)||chr(127)||
                         to_char(v_br_audit_rec(indx).bfr_date,'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                         to_char(v_br_audit_rec(indx).aft_date,'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                         to_char(v_br_audit_rec(indx).whichone)||chr(127)||
                         to_char(v_br_audit_rec(indx).recmethod)||chr(127)||
                         to_char(v_br_audit_rec(indx).bfr_amt)||chr(127)||
                         to_char(v_br_audit_rec(indx).aft_amt)||chr(127)||
                         to_char(v_br_audit_rec(indx).num_in_grp)||chr(127)||
                         to_char(v_br_audit_rec(indx).pass_id)||chr(127)||
                         to_char(v_br_audit_rec(indx).spare_one)||chr(127)||
                         to_char(v_br_audit_rec(indx).spare_two);


                replace_tab_cr_line_feed(l_str);

                utl_file.put_line(file_id_audit, l_str);

              end loop;

            end if; -- p_deletereturnsrows = 1

        end if; -- v_br_audit_rec.count > 0

        commit;

      v_begRecordRange := v_endRecordRange + 1;
      v_endRecordRange := v_endRecordRange + p_purgeBlockSize;

    end loop;


    if p_eventlogtiming = 1 then
      v_endtime := sysdate;
      v_timediff := (v_endtime - v_starttime) * 86400;  -- time given in seconds
      pkg_bs_log_event.pr_log_timing(p_instance_id => 0
                                    ,p_program_id => 11
                                    ,p_message => 'CA Audit records purged '||to_char(v_tot_rows_processed)||' rows deleted.'
                                    ,p_extra_text => 'Duration: '||to_char(v_timeDiff)||' seconds'
                                    ,p_category_id => 1
                                    ,p_success => v_success);
    end if;

    v_success := 1;
    p_success := v_success;

    if p_deletereturnsrows = 1 then
        utl_file.fclose(file_id_ca_audit);
        utl_file.fclose(file_id_audit);

        file_id_ca_audit.id := null;
        file_id_audit.id := null;
    end if;

    commit;

    exception
    when others then
      if p_deletereturnsrows = 1 then
         utl_file.fclose(file_id_ca_audit);
         utl_file.fclose(file_id_audit);

         file_id_ca_audit.id := null;
         file_id_audit.id := null;
      end if;
      p_errReason := 'pr_purge_ca_audit_records';
      Pkg_Bs_Log_Event.pr_log_error (p_instance_id => 0
                                    ,p_severity_id => 0
                                    ,p_message => 'Error calling pkg_br_purge.pr_purge_ca_audit_records'
                                    ,p_extra_text => 'Server Error '||to_char(sqlcode)||' '||sqlerrm
                                    ,p_category_id => 1
                                    ,p_success => v_success
                                    );

      -- no re-raise as caller does not handle exceptions, so return failure code
      p_success := 0;
      rollback;

  end pr_purge_ca_audit_records;

  /****************************************************************************
   Name:    pr_purge_data_records
   Date:    28-Mar-2006
   Author:  S.Mace
   Purpose: This procedure is part of the text purge routine and deletes the br_data
            records associated with the br_data rows held in the specified temporary
      table. The deletion is managed by deleting a set number of records at a
      time in a loop - this is to avoid the job failing for a high number of
      deletions when extents may otherwise be blown.


            The activity may optionally be timed and the result put into the bs_event_log table.

   Change History
   --------------
   Date     Author              Description of change
   ----     ------              ---------------------
   20-08-07 S.Mace              Removed p_maxAuditId as unused.
  *****************************************************************************/

  PROCEDURE pr_purge_data_records(p_tempTableName     IN VARCHAR2
                                 ,p_acctId            IN INTEGER := 0
                                 ,p_eventLogTiming    IN INTEGER := 0
                                 ,p_purgeBlockSize    IN INTEGER := 0
                                 ,p_timestamp         IN VARCHAR2
                                 ,p_version           IN VARCHAR2
                                 ,p_deleteReturnsRows IN INTEGER := 0
                                 ,p_purgeFilesDir     IN VARCHAR2
                                 ,p_success           OUT INTEGER
                                 ,p_errReason         OUT VARCHAR2
                                 )
  IS
  v_timeDiff            INTEGER := 0;
  v_success             INTEGER := 0; -- defaulted to failure
  v_begRecordRange      INTEGER := 0;
  v_endRecordRange      INTEGER := 0;
  v_cursor_name         INTEGER;
  v_rows_processed      INTEGER;
  v_tot_rows_processed  INTEGER := 0;
  v_startTime           DATE;
  v_endTime             DATE;
  file_id2              UTL_FILE.FILE_TYPE;
  l_str                 VARCHAR2(5000);
  l_acct_name           VARCHAR2(255);
  v_file_name     VARCHAR2(40) := p_timestamp||'_'||to_char(p_acctid)||'_'||'br_data.txt';

  TYPE v_data_recs1 IS TABLE OF BR_DATA.ACCT_ID%TYPE;
  TYPE v_data_recs2 IS TABLE OF BR_DATA.RECORD_ID%TYPE;
  TYPE v_data_recs3 IS TABLE OF BR_DATA.STATE%TYPE;
  TYPE v_data_recs4 IS TABLE OF BR_DATA.CS_FLAG%TYPE;
  TYPE v_data_recs5 IS TABLE OF BR_DATA.PR_FLAG%TYPE;
  TYPE v_data_recs6 IS TABLE OF BR_DATA.PP_FLAG%TYPE;
  TYPE v_data_recs7 IS TABLE OF BR_DATA.TRANS_DATE%TYPE;
  TYPE v_data_recs8 IS TABLE OF BR_DATA.VALUE_DATE%TYPE;
  TYPE v_data_recs9 IS TABLE OF BR_DATA.NARRATIVE%TYPE;
  TYPE v_data_recs10 IS TABLE OF BR_DATA.INTL_REF%TYPE;
  TYPE v_data_recs11 IS TABLE OF BR_DATA.EXTL_REF%TYPE;
  TYPE v_data_recs12 IS TABLE OF BR_DATA.AMOUNT%TYPE;
  TYPE v_data_recs13 IS TABLE OF BR_DATA.TRANS_TYPE%TYPE;
  TYPE v_data_recs14 IS TABLE OF BR_DATA.USER_ONE%TYPE;
  TYPE v_data_recs15 IS TABLE OF BR_DATA.USER_TWO%TYPE;
  TYPE v_data_recs16 IS TABLE OF BR_DATA.USER_THREE%TYPE;
  TYPE v_data_recs17 IS TABLE OF BR_DATA.USER_FOUR%TYPE;
  TYPE v_data_recs18 IS TABLE OF BR_DATA.USER_FIVE%TYPE;
  TYPE v_data_recs19 IS TABLE OF BR_DATA.USER_SIX%TYPE;
  TYPE v_data_recs20 IS TABLE OF BR_DATA.UPD_TIME%TYPE;
  TYPE v_data_recs21 IS TABLE OF BR_DATA.REC_GROUP%TYPE;
  TYPE v_data_recs22 IS TABLE OF BR_DATA.ORIG_CCY%TYPE;
  TYPE v_data_recs23 IS TABLE OF BR_DATA.NUM_NOTES%TYPE;
  TYPE v_data_recs24 IS TABLE OF BR_DATA.NOTE_GROUP%TYPE;
  TYPE v_data_recs25 IS TABLE OF BR_DATA.ORIG_ID%TYPE;
  TYPE v_data_recs26 IS TABLE OF BR_DATA.NOTE_ADD%TYPE;
  TYPE v_data_recs27 IS TABLE OF BR_DATA.WF_STATUS%TYPE;
  TYPE v_data_recs28 IS TABLE OF BR_DATA.WF_REF%TYPE;
  TYPE v_data_recs29 IS TABLE OF BR_DATA.CREATEDBY%TYPE;
  TYPE v_data_recs30 IS TABLE OF BR_DATA.RECMETHOD%TYPE;
  TYPE v_data_recs31 IS TABLE OF BR_DATA.DEPARTMENT%TYPE;
  TYPE v_data_recs32 IS TABLE OF BR_DATA.LASTAUDIT%TYPE;
  TYPE v_data_recs33 IS TABLE OF BR_DATA.SUB_ACCT%TYPE;
  TYPE v_data_recs34 IS TABLE OF BR_DATA.LOCK_FLG%TYPE;
  TYPE v_data_recs35 IS TABLE OF BR_DATA.ALT_AMT%TYPE;
  TYPE v_data_recs36 IS TABLE OF BR_DATA.NUM_IN_GRP%TYPE;
  TYPE v_data_recs37 IS TABLE OF BR_DATA.PASS_ID%TYPE;
  TYPE v_data_recs38 IS TABLE OF BR_DATA.FLAG_A%TYPE;
  TYPE v_data_recs39 IS TABLE OF BR_DATA.FLAG_B%TYPE;
  TYPE v_data_recs40 IS TABLE OF BR_DATA.FLAG_C%TYPE;
  TYPE v_data_recs41 IS TABLE OF BR_DATA.FLAG_D%TYPE;
  TYPE v_data_recs42 IS TABLE OF BR_DATA.FLAG_E%TYPE;
  TYPE v_data_recs43 IS TABLE OF BR_DATA.FLAG_F%TYPE;
  TYPE v_data_recs44 IS TABLE OF BR_DATA.FLAG_G%TYPE;
  TYPE v_data_recs45 IS TABLE OF BR_DATA.FLAG_H%TYPE;
  TYPE v_data_recs46 IS TABLE OF BR_DATA.QUANTITY%TYPE;
  TYPE v_data_recs47 IS TABLE OF BR_DATA.USER_DEC_A%TYPE;
  TYPE v_data_recs48 IS TABLE OF BR_DATA.UNITPRICE%TYPE;
  TYPE v_data_recs49 IS TABLE OF BR_DATA.USERDATE_A%TYPE;
  TYPE v_data_recs50 IS TABLE OF BR_DATA.USERDATE_B%TYPE;
  TYPE v_data_recs51 IS TABLE OF BR_DATA.USER_SEVEN%TYPE;
  TYPE v_data_recs52 IS TABLE OF BR_DATA.USER_EIGHT%TYPE;
  TYPE v_data_recs53 IS TABLE OF BR_DATA.PERIOD%TYPE;
  TYPE v_data_recs54 IS TABLE OF BR_DATA.LAST_NOTE_TEXT%TYPE;
  TYPE v_data_recs55 IS TABLE OF BR_DATA.LAST_NOTE_USER%TYPE;
  TYPE v_data_recs56 IS TABLE OF BR_DATA.IS_UNDER_INV%TYPE;
  TYPE v_data_recs57 IS TABLE OF BR_DATA.USER_NINE%TYPE;
  TYPE v_data_recs58 IS TABLE OF BR_DATA.USER_TEN%TYPE;
  TYPE v_data_recs59 IS TABLE OF BR_DATA.USER_ELEVEN%TYPE;
  TYPE v_data_recs60 IS TABLE OF BR_DATA.USER_TWELVE%TYPE;
  TYPE v_data_recs61 IS TABLE OF BR_DATA.USER_THIRTEEN%TYPE;
  TYPE v_data_recs62 IS TABLE OF BR_DATA.USER_FOURTEEN%TYPE;
  TYPE v_data_recs63 IS TABLE OF BR_DATA.USER_FIFTEEN%TYPE;
  TYPE v_data_recs64 IS TABLE OF BR_DATA.USER_SIXTEEN%TYPE;
  TYPE v_data_recs65 IS TABLE OF BR_DATA.USERDATE_C%TYPE;
  TYPE v_data_recs66 IS TABLE OF BR_DATA.USERDATE_D%TYPE;
  TYPE v_data_recs67 IS TABLE OF BR_DATA.USER_DEC_B%TYPE;
  TYPE v_data_recs68 IS TABLE OF BR_DATA.USER_DEC_C%TYPE;
  TYPE v_data_recs69 IS TABLE OF BR_DATA.USER_DEC_D%TYPE;
  TYPE v_data_recs70 IS TABLE OF BR_DATA.LOAD_ID%TYPE;
  TYPE v_data_recs71 IS TABLE OF BR_DATA.DIFF_REF%TYPE;
  TYPE v_data_recs72 IS TABLE OF BR_DATA.CREATED_DATE%TYPE;
  l_data_recs1 v_data_recs1;
  l_data_recs2 v_data_recs2;
  l_data_recs3 v_data_recs3;
  l_data_recs4 v_data_recs4;
  l_data_recs5 v_data_recs5;
  l_data_recs6 v_data_recs6;
  l_data_recs7 v_data_recs7;
  l_data_recs8 v_data_recs8;
  l_data_recs9 v_data_recs9;
  l_data_recs10 v_data_recs10;
  l_data_recs11 v_data_recs11;
  l_data_recs12 v_data_recs12;
  l_data_recs13 v_data_recs13;
  l_data_recs14 v_data_recs14;
  l_data_recs15 v_data_recs15;
  l_data_recs16 v_data_recs16;
  l_data_recs17 v_data_recs17;
  l_data_recs18 v_data_recs18;
  l_data_recs19 v_data_recs19;
  l_data_recs20 v_data_recs20;
  l_data_recs21 v_data_recs21;
  l_data_recs22 v_data_recs22;
  l_data_recs23 v_data_recs23;
  l_data_recs24 v_data_recs24;
  l_data_recs25 v_data_recs25;
  l_data_recs26 v_data_recs26;
  l_data_recs27 v_data_recs27;
  l_data_recs28 v_data_recs28;
  l_data_recs29 v_data_recs29;
  l_data_recs30 v_data_recs30;
  l_data_recs31 v_data_recs31;
  l_data_recs32 v_data_recs32;
  l_data_recs33 v_data_recs33;
  l_data_recs34 v_data_recs34;
  l_data_recs35 v_data_recs35;
  l_data_recs36 v_data_recs36;
  l_data_recs37 v_data_recs37;
  l_data_recs38 v_data_recs38;
  l_data_recs39 v_data_recs39;
  l_data_recs40 v_data_recs40;
  l_data_recs41 v_data_recs41;
  l_data_recs42 v_data_recs42;
  l_data_recs43 v_data_recs43;
  l_data_recs44 v_data_recs44;
  l_data_recs45 v_data_recs45;
  l_data_recs46 v_data_recs46;
  l_data_recs47 v_data_recs47;
  l_data_recs48 v_data_recs48;
  l_data_recs49 v_data_recs49;
  l_data_recs50 v_data_recs50;
  l_data_recs51 v_data_recs51;
  l_data_recs52 v_data_recs52;
  l_data_recs53 v_data_recs53;
  l_data_recs54 v_data_recs54;
  l_data_recs55 v_data_recs55;
  l_data_recs56 v_data_recs56;
  l_data_recs57 v_data_recs57;
  l_data_recs58 v_data_recs58;
  l_data_recs59 v_data_recs59;
  l_data_recs60 v_data_recs60;
  l_data_recs61 v_data_recs61;
  l_data_recs62 v_data_recs62;
  l_data_recs63 v_data_recs63;
  l_data_recs64 v_data_recs64;
  l_data_recs65 v_data_recs65;
  l_data_recs66 v_data_recs66;
  l_data_recs67 v_data_recs67;
  l_data_recs68 v_data_recs68;
  l_data_recs69 v_data_recs69;
  l_data_recs70 v_data_recs70;
  l_data_recs71 v_data_recs71;
  l_data_recs72 v_data_recs72;


  BEGIN

    IF p_eventLogTiming = 1
    THEN
      v_startTime := sysdate;
    END IF;
    --
    -- prepare to purge data records associated with those loaded in the temporary table
    --
    --
    -- reinitialise variables controlling number of records processed per loop
    --
    v_begRecordRange := g_min_record_id;
    v_endRecordRange := g_min_record_id + p_purgeBlockSize;
    --

    IF p_deleteReturnsRows = 1 THEN
      file_id2 := UTL_FILE.FOPEN(p_PurgeFilesDir,v_file_name,'a',32767);

      SELECT acct_name
      INTO l_acct_name
      FROM BS_ACCTS
      WHERE acct_id = p_acctid;

      l_str := p_timestamp||chr(127)||'br_data'||chr(127)||p_version||chr(127)||to_char(p_acctid)||chr(127)||l_acct_name;

      UTL_FILE.PUT_LINE(file_id2, l_str);

      l_str :=  'ACCT_ID'||chr(127)||
                'RECORD_ID'||chr(127)||
                'STATE'||chr(127)||
                'CS_FLAG'||chr(127)||
                'PR_FLAG'||chr(127)||
                'PP_FLAG'||chr(127)||
                'TRANS_DATE'||chr(127)||
                'VALUE_DATE'||chr(127)||
                'NARRATIVE'||chr(127)||
                'INTL_REF'||chr(127)||
                'EXTL_REF'||chr(127)||
                'AMOUNT'||chr(127)||
                'TRANS_TYPE'||chr(127)||
                'USER_ONE'||chr(127)||
                'USER_TWO'||chr(127)||
                'USER_THREE'||chr(127)||
                'USER_FOUR'||chr(127)||
                'USER_FIVE'||chr(127)||
                'USER_SIX'||chr(127)||
                'UPD_TIME'||chr(127)||
                'REC_GROUP'||chr(127)||
                'ORIG_CCY'||chr(127)||
                'NUM_NOTES'||chr(127)||
                'NOTE_GROUP'||chr(127)||
                'ORIG_ID'||chr(127)||
                'NOTE_ADD'||chr(127)||
                'WF_STATUS'||chr(127)||
                'WF_REF'||chr(127)||
                'CREATEDBY'||chr(127)||
                'RECMETHOD'||chr(127)||
                'DEPARTMENT'||chr(127)||
                'LASTAUDIT'||chr(127)||
                'SUB_ACCT'||chr(127)||
                'LOCK_FLG'||chr(127)||
                'ALT_AMT'||chr(127)||
                'NUM_IN_GRP'||chr(127)||
                'PASS_ID'||chr(127)||
                'FLAG_A'||chr(127)||
                'FLAG_B'||chr(127)||
                'FLAG_C'||chr(127)||
                'FLAG_D'||chr(127)||
                'FLAG_E'||chr(127)||
                'FLAG_F'||chr(127)||
                'FLAG_G'||chr(127)||
                'FLAG_H'||chr(127)||
                'QUANTITY'||chr(127)||
                'USER_DEC_A'||chr(127)||
                'UNITPRICE'||chr(127)||
                'USERDATE_A'||chr(127)||
                'USERDATE_B'||chr(127)||
                'USER_SEVEN'||chr(127)||
                'USER_EIGHT'||chr(127)||
                'PERIOD'||chr(127)||
                'LAST_NOTE_TEXT'||chr(127)||
                'LAST_NOTE_USER'||chr(127)||
                'IS_UNDER_INV'||chr(127)||
                'USER_NINE'||chr(127)||
                'USER_TEN'||chr(127)||
                'USER_ELEVEN'||chr(127)||
                'USER_TWELVE'||chr(127)||
                'USER_THIRTEEN'||chr(127)||
                'USER_FOURTEEN'||chr(127)||
                'USER_FIFTEEN'||chr(127)||
                'USER_SIXTEEN'||chr(127)||
                'USERDATE_C'||chr(127)||
                'USERDATE_D'||chr(127)||
                'USER_DEC_B'||chr(127)||
                'USER_DEC_C'||chr(127)||
                'USER_DEC_D'||chr(127)||
                'LOAD_ID'||chr(127)||
                'DIFF_REF'||chr(127)||
                'CREATED_DATE';

      UTL_FILE.PUT_LINE(file_id2, l_str);

    END IF;

    WHILE (v_begRecordRange <= g_max_record_id)
    LOOP

      EXECUTE IMMEDIATE 'DELETE '||
                        'FROM BR_DATA BRD '||
                        'WHERE BRD.ACCT_ID = :1 '||
                        'AND   brd.record_id BETWEEN :2 and :3  '||
                        'AND exists (select ''x'' from '||p_tempTableName||
                        '            where acct_id = brd.acct_id '||
                        '          and record_id = brd.record_id) '||
                        '  returning  ACCT_ID,
                                      RECORD_ID,
                                      STATE,
                                      CS_FLAG,
                                      PR_FLAG,
                                      PP_FLAG,
                                      TRANS_DATE,
                                      VALUE_DATE,
                                      NARRATIVE,
                                      INTL_REF,
                                      EXTL_REF,
                                      AMOUNT,
                                      TRANS_TYPE,
                                      USER_ONE,
                                      USER_TWO,
                                      USER_THREE,
                                      USER_FOUR,
                                      USER_FIVE,
                                      USER_SIX,
                                      UPD_TIME,
                                      REC_GROUP,
                                      ORIG_CCY,
                                      NUM_NOTES,
                                      NOTE_GROUP,
                                      ORIG_ID,
                                      NOTE_ADD,
                                      WF_STATUS,
                                      WF_REF,
                                      CREATEDBY,
                                      RECMETHOD,
                                      DEPARTMENT,
                                      LASTAUDIT,
                                      SUB_ACCT,
                                      LOCK_FLG,
                                      ALT_AMT,
                                      NUM_IN_GRP,
                                      PASS_ID,
                                      FLAG_A,
                                      FLAG_B,
                                      FLAG_C,
                                      FLAG_D,
                                      FLAG_E,
                                      FLAG_F,
                                      FLAG_G,
                                      FLAG_H,
                                      QUANTITY,
                                      USER_DEC_A,
                                      UNITPRICE,
                                      USERDATE_A,
                                      USERDATE_B,
                                      USER_SEVEN,
                                      USER_EIGHT,
                                      PERIOD,
                                      LAST_NOTE_TEXT,
                                      LAST_NOTE_USER,
                                      IS_UNDER_INV,
                                      USER_NINE,
                                      USER_TEN,
                                      USER_ELEVEN,
                                      USER_TWELVE,
                                      USER_THIRTEEN,
                                      USER_FOURTEEN,
                                      USER_FIFTEEN,
                                      USER_SIXTEEN,
                                      USERDATE_C,
                                      USERDATE_D,
                                      USER_DEC_B,
                                      USER_DEC_C,
                                      USER_DEC_D,
                                      LOAD_ID,
                                      DIFF_REF,
                                      CREATED_DATE
                         INTO :4,:5,:6,:7,:8,:9,:10,:11,:12,:13,:14,:15,:16,:17,:18,:19,:20,:21,:22,:23,:24,
                              :25,:26,:27,:28,:29,:30,:31,:32,:33,:34,:35,:36,:37,:38,:39,:40,:41,:42,:43,:44,
                              :45,:46,:47,:48,:49,:50,:51,:52,:53,:54,:55,:56,:57,:58,:59,:60,:61,:62,:63,:64,:65,:66,
                              :67,:68,:69,:70,:71,:72,:73,:74,:75 '
      using p_acctId,v_begRecordRange,v_endRecordRange RETURNING BULK COLLECT INTO
        l_data_recs1,
        l_data_recs2,
        l_data_recs3,
        l_data_recs4,
        l_data_recs5,
        l_data_recs6,
        l_data_recs7,
        l_data_recs8,
        l_data_recs9,
        l_data_recs10,
        l_data_recs11,
        l_data_recs12,
        l_data_recs13,
        l_data_recs14,
        l_data_recs15,
        l_data_recs16,
        l_data_recs17,
        l_data_recs18,
        l_data_recs19,
        l_data_recs20,
        l_data_recs21,
        l_data_recs22,
        l_data_recs23,
        l_data_recs24,
        l_data_recs25,
        l_data_recs26,
        l_data_recs27,
        l_data_recs28,
        l_data_recs29,
        l_data_recs30,
        l_data_recs31,
        l_data_recs32,
        l_data_recs33,
        l_data_recs34,
        l_data_recs35,
        l_data_recs36,
        l_data_recs37,
        l_data_recs38,
        l_data_recs39,
        l_data_recs40,
        l_data_recs41,
        l_data_recs42,
        l_data_recs43,
        l_data_recs44,
        l_data_recs45,
        l_data_recs46,
        l_data_recs47,
        l_data_recs48,
        l_data_recs49,
        l_data_recs50,
        l_data_recs51,
        l_data_recs52,
        l_data_recs53,
        l_data_recs54,
        l_data_recs55,
        l_data_recs56,
        l_data_recs57,
        l_data_recs58,
        l_data_recs59,
        l_data_recs60,
        l_data_recs61,
        l_data_recs62,
        l_data_recs63,
        l_data_recs64,
        l_data_recs65,
        l_data_recs66,
        l_data_recs67,
        l_data_recs68,
        l_data_recs69,
        l_data_recs70,
        l_data_recs71,
        l_data_recs72;

      IF l_data_recs1.count > 0 THEN
        v_tot_rows_processed := v_tot_rows_processed + l_data_recs1.count;

        IF p_deleteReturnsRows = 1 THEN

          FOR indx IN l_data_recs1.first .. l_data_recs1.last
          LOOP

            l_str := to_char(l_data_recs1(indx))||chr(127)||
                     to_char(l_data_recs2(indx))||chr(127)||
                     to_char(l_data_recs3(indx))||chr(127)||
                     l_data_recs4(indx)||chr(127)||
                     l_data_recs5(indx)||chr(127)||
                     l_data_recs6(indx)||chr(127)||
                     to_char(l_data_recs7(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                     to_char(l_data_recs8(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                     l_data_recs9(indx)||chr(127)||
                     l_data_recs10(indx)||chr(127)||
                     l_data_recs11(indx)||chr(127)||
                     to_char(l_data_recs12(indx))||chr(127)||
                     l_data_recs13(indx)||chr(127)||
                     to_char(l_data_recs14(indx))||chr(127)||
                     to_char(l_data_recs15(indx))||chr(127)||
                     l_data_recs16(indx)||chr(127)||
                     l_data_recs17(indx)||chr(127)||
                     l_data_recs18(indx)||chr(127)||
                     l_data_recs19(indx)||chr(127)||
                     to_char(l_data_recs20(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                     to_char(l_data_recs21(indx))||chr(127)||
                     l_data_recs22(indx)||chr(127)||
                     to_char(l_data_recs23(indx))||chr(127)||
                     to_char(l_data_recs24(indx))||chr(127)||
                     to_char(l_data_recs25(indx))||chr(127)||
                     to_char(l_data_recs26(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                     to_char(l_data_recs27(indx))||chr(127)||
                     l_data_recs28(indx)||chr(127)||
                     to_char(l_data_recs29(indx))||chr(127)||
                     to_char(l_data_recs30(indx))||chr(127)||
                     to_char(l_data_recs31(indx))||chr(127)||
                     to_char(l_data_recs32(indx))||chr(127)||
                     to_char(l_data_recs33(indx))||chr(127)||
                     to_char(l_data_recs34(indx))||chr(127)||
                     to_char(l_data_recs35(indx))||chr(127)||
                     to_char(l_data_recs36(indx))||chr(127)||
                     to_char(l_data_recs37(indx))||chr(127)||
                     l_data_recs38(indx)||chr(127)||
                     l_data_recs39(indx)||chr(127)||
                     l_data_recs40(indx)||chr(127)||
                     l_data_recs41(indx)||chr(127)||
                     l_data_recs42(indx)||chr(127)||
                     l_data_recs43(indx)||chr(127)||
                     l_data_recs44(indx)||chr(127)||
                     l_data_recs45(indx)||chr(127)||
                     to_char(l_data_recs46(indx))||chr(127)||
                     to_char(l_data_recs47(indx))||chr(127)||
                     to_char(l_data_recs48(indx))||chr(127)||
                     to_char(l_data_recs49(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                     to_char(l_data_recs50(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                     l_data_recs51(indx)||chr(127)||
                     l_data_recs52(indx)||chr(127)||
                     l_data_recs53(indx)||chr(127)||
                     l_data_recs54(indx)||chr(127)||
                     to_char(l_data_recs55(indx))||chr(127)||
                     l_data_recs56(indx)||chr(127)||
                     l_data_recs57(indx)||chr(127)||
                     l_data_recs58(indx)||chr(127)||
                     l_data_recs59(indx)||chr(127)||
                     l_data_recs60(indx)||chr(127)||
                     l_data_recs61(indx)||chr(127)||
                     l_data_recs62(indx)||chr(127)||
                     l_data_recs63(indx)||chr(127)||
                     l_data_recs64(indx)||chr(127)||
                     to_char(l_data_recs65(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                     to_char(l_data_recs66(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                     to_char(l_data_recs67(indx))||chr(127)||
                     to_char(l_data_recs68(indx))||chr(127)||
                     to_char(l_data_recs69(indx))||chr(127)||
                     to_char(l_data_recs70(indx))||chr(127)||
                     to_char(l_data_recs71(indx))||chr(127)||
                     to_char(l_data_recs72(indx),'yyyy/mm/dd hh24:mi:ss');

            replace_tab_cr_line_feed(l_str);

            UTL_FILE.PUT_LINE(file_id2, l_str);
          END LOOP;

        END IF;

      END IF;

      COMMIT;

      --
      -- increment the records to be processed in the next loop
      --
      v_begRecordRange := v_endRecordRange + 1;
      v_endRecordRange := v_endRecordRange + p_purgeBlockSize;
      --
    END LOOP;

    COMMIT;

    IF p_deleteReturnsRows = 1 THEN

      UTL_FILE.FCLOSE(file_id2);
      file_id2.ID := NULL;

    END IF;

    IF p_eventLogTiming = 1
    THEN
      v_endTime := sysdate;

      v_timeDiff := (v_endTime - v_startTime) * 86400;  -- time given in seconds
      v_rows_processed := v_rows_processed + v_rows_processed;
      Pkg_Bs_Log_Event.pr_log_timing(p_instance_id => 0
                                    ,p_program_id => 11
                                    ,p_message => 'BR data records purged '||to_char(v_tot_rows_processed)||' rows deleted.'
                                    ,p_extra_text => 'Duration: '||to_char(v_timeDiff)||' seconds'
                                    ,p_category_id => 1
                                    ,p_success => v_success);
    END IF;

    v_success := 1;
    p_success := v_success;

  EXCEPTION
  WHEN OTHERS THEN

    IF p_deleteReturnsRows = 1 THEN
      UTL_FILE.FCLOSE(file_id2);
      file_id2.ID := NULL;
    END IF;

    p_errReason := 'purge_data_records';
    Pkg_Bs_Log_Event.pr_log_error (p_instance_id => 0
                                  ,p_severity_id => 0
                                  ,p_message => 'Error calling pkg_br_purge.pr_purge_data_records'
                                  ,p_extra_text => 'Server Error '||to_char(SQLCODE)||' '||SQLERRM
                                  ,p_category_id => 1
                                  ,p_success => v_success
                                  );
    p_success := 0;                  -- calling program needs to know exception raised

  END pr_purge_data_records;


  /* ****************************************************************************
   Name:    pr_purge_note_group_holdings
   Date:    28-Mar-2006
   Author:  S.Mace
   Purpose: This procedure is part of the text purge routine and deletes the br_notes
            records. This procedure is designed for holdings accounts. The deletion is
            managed by deleting a set number of records at a time in a loop - this is
            to avoid the job failing for a high number of deletions when extents may
            otherwise be blown.

            The activity may optionally be timed and the result put into the bs_event_log table.


   Change History
   --------------
   Date     Author              Description of change
   ----     ------              ---------------------
   20-08-07 S.Mace              Replace p_maxAuditId with g_sequence_num for AS_ID's changes
                                in 2.12.1
  *****************************************************************************/

  PROCEDURE pr_purge_note_group_holdings(p_acctId          IN INTEGER := 0
                                        ,p_eventLogTiming  IN INTEGER := 0
                                        ,p_purgeBlockSize  IN INTEGER := 0
                                        ,p_timestamp     IN VARCHAR2
                                        ,p_version         IN VARCHAR2
                                        ,p_deleteReturnsRows IN INTEGER := 0
                                        ,p_purgeFilesDir   IN VARCHAR2
                                        ,p_success        OUT INTEGER
                                        ,p_errReason OUT VARCHAR2
                                        )

  IS
  v_timeDiff            INTEGER := 0;
  v_success             INTEGER := 0; -- defaulted to failure
  v_begPurgeRange       INTEGER := 0;
  v_endPurgeRange       INTEGER := 0;
  v_cursor_name         INTEGER;
  v_rows_processed      INTEGER;
  v_tot_rows_processed  INTEGER := 0;
  v_startTime           DATE;
  v_endTime             DATE;
  file_id3        UTL_FILE.FILE_TYPE;
  l_str         VARCHAR2(5000);
  l_acct_name       VARCHAR2(255);
  v_file_name     VARCHAR2(40) := p_timestamp||'_'||to_char(p_acctid)||'_'||'br_notes.txt';

  TYPE v_data_recs1 IS TABLE OF BR_NOTES.acct_id%TYPE;
  TYPE v_data_recs2 IS TABLE OF BR_NOTES.note_id%TYPE;
  TYPE v_data_recs3 IS TABLE OF BR_NOTES.note_group%TYPE;
  TYPE v_data_recs4 IS TABLE OF BR_NOTES.note_seq%TYPE;
  TYPE v_data_recs5 IS TABLE OF BR_NOTES.text%TYPE;
  TYPE v_data_recs6 IS TABLE OF BR_NOTES.intl_ref%TYPE;
  l_data_recs1 v_data_recs1;
  l_data_recs2 v_data_recs2;
  l_data_recs3 v_data_recs3;
  l_data_recs4 v_data_recs4;
  l_data_recs5 v_data_recs5;
  l_data_recs6 v_data_recs6;

  BEGIN

    IF p_eventLogTiming = 1
    THEN
      v_startTime := sysdate;
    END IF;

    --
    -- prepare to purge notes records
    --
    --
    -- Set the range of records to be processed
    --
    v_begPurgeRange := 0;
    v_endPurgeRange := p_purgeBlockSize;
    --


    if p_deleteReturnsRows = 1 then

        if (DEBUG_ON) then

            log_debug('File name:' || v_file_name, 'p_PurgeFilesDir:' || p_PurgeFilesDir);
        end if;

        file_id3 := UTL_FILE.FOPEN(p_PurgeFilesDir,v_file_name,'a',32767);
    end if;

    WHILE (v_endPurgeRange <= g_sequence_num)
    LOOP

      delete from br_notes bn
      where bn.acct_id = p_acctId
      and bn.note_group IN (select distinct bd.note_group
                            from br_data bd
                                ,br_audit ba
                            where bd.acct_id = bn.acct_id
                            and ba.acct_id = bd.acct_id
                            and bd.state IN (4,6)
                            and bd.lastaudit = ba.audit_id
                            and ba.sequence_num between v_begPurgeRange and v_endPurgeRange
                            and bd.note_group > 0
                            and (bd.cs_flag = 'R' OR bd.cs_flag = 'B'))
      returning bn.acct_id,bn.note_id,bn.note_group,bn.note_seq,bn.text,bn.intl_ref
      bulk collect into   l_data_recs1,
                          l_data_recs2,
                          l_data_recs3,
                          l_data_recs4,
                          l_data_recs5,
                          l_data_recs6;

      IF l_data_recs1.count > 0 THEN

        v_tot_rows_processed := v_tot_rows_processed + l_data_recs1.count;

        IF p_deleteReturnsRows = 1 THEN

          FOR indx IN l_data_recs1.first .. l_data_recs1.last
          LOOP
            l_str := to_char(l_data_recs1(indx))||chr(127)||
                     to_char(l_data_recs2(indx))||chr(127)||
                     to_char(l_data_recs3(indx))||chr(127)||
                     to_char(l_data_recs4(indx))||chr(127)||
                     l_data_recs5(indx)||chr(127)||
                     l_data_recs6(indx);

            replace_tab_cr_line_feed(l_str);

            UTL_FILE.PUT_LINE(file_id3, l_str);
          END LOOP;
        END IF;
      END IF;


      --
      COMMIT;
      --
      -- increment the variables for the record range to be processed in the next loop
      --
      v_begPurgeRange := v_endPurgeRange + 1;
      v_endPurgeRange := v_endPurgeRange + p_purgeBlockSize;

    END LOOP;

    COMMIT;

    IF p_deleteReturnsRows = 1 THEN
      UTL_FILE.FCLOSE(file_id3);
      file_id3.ID := NULL;
    END IF;


    IF p_eventLogTiming = 1 THEN
      v_endTime := sysdate;
      v_timeDiff := (v_endTime - v_startTime) * 86400;  -- time given in seconds

      Pkg_Bs_Log_Event.pr_log_timing(p_instance_id => 0
                                    ,p_program_id => 11
                                    ,p_message => 'Holding Group Notes purged: '||to_char(v_tot_rows_processed)||' rows deleted.'
                                    ,p_extra_text => 'Duration: '||to_char(v_timeDiff)||' seconds'
                                    ,p_category_id => 1
                                    ,p_success => v_success);
    END IF;

    v_success := 1;
    p_success := v_success;

  EXCEPTION
  WHEN OTHERS THEN

    IF p_deleteReturnsRows = 1 THEN
     UTL_FILE.FCLOSE(file_id3);
     file_id3.ID := NULL;
    END IF;
    p_errReason := 'pr_purge_note_group_holdings';

    Pkg_Bs_Log_Event.pr_log_error (p_instance_id => 0
                                  ,p_severity_id => 0
                                  ,p_message => 'Error calling pkg_br_purge.pr_purge_note_group_holdings'
                                  ,p_extra_text => 'Server Error '||to_char(SQLCODE)||' '||SQLERRM
                                  ,p_category_id => 1
                                  ,p_success => v_success
                                  );
    p_success := 0;  -- calling program needs to know exception raised
  END pr_purge_note_group_holdings;


  /*****************************************************************************
   Name:    pr_purge_note_group

   Date:    28-Mar-2006
   Author:  S.Mace
   Purpose: This procedure is part of the text purge routine and deletes some br_notes
            records associated with the br_data rows held in the specified temporary
            table. The deletion is managed by deleting a set number of records at a
            time in a loop - this is to avoid the job failing for a high number of
            deletions when extents may otherwise be blown.

            The activity may optionally be timed and the result put into the bs_event_log table.

   Change History
   --------------
   Date     Author              Description of change

   ----     ------              ---------------------
   9-5-06   S.Mace       Delete statement now uses temporary table as driver.
   20-08-07 S.Mace              Replace p_maxAuditId with global

  *****************************************************************************/


  PROCEDURE pr_purge_note_group(p_tempTableName     IN VARCHAR2
                               ,p_acctId            IN INTEGER := 0
                               ,p_eventLogTiming    IN INTEGER := 0
                               ,p_purgeBlockSize    IN INTEGER := 0
                               ,p_timestamp         IN VARCHAR2
                               ,p_version           IN VARCHAR2
                               ,p_deleteReturnsRows IN INTEGER := 0
                               ,p_purgeFilesDir     IN VARCHAR2
                               ,p_success           OUT INTEGER
                               ,p_errReason         OUT VARCHAR2
                               )
  IS
  v_timeDiff            INTEGER := 0;
  v_success             INTEGER := 0; -- defaulted to failure
  v_begRecordRange      INTEGER := 0;
  v_endRecordRange      INTEGER := 0;
  v_cursor_name         INTEGER;
  v_rows_processed      INTEGER;
  v_tot_rows_processed  INTEGER := 0;
  v_startTime           DATE;
  v_endTime             DATE;
  file_id4              UTL_FILE.FILE_TYPE;
  l_str                 VARCHAR2(5000);
  l_acct_name           VARCHAR2(255);
  v_file_name            VARCHAR2(40) := p_timestamp||'_'||to_char(p_acctid)||'_'||'br_notes.txt';

  TYPE v_data_recs1 IS TABLE OF BR_NOTES.acct_id%TYPE;
  TYPE v_data_recs2 IS TABLE OF BR_NOTES.note_id%TYPE;
  TYPE v_data_recs3 IS TABLE OF BR_NOTES.note_group%TYPE;
  TYPE v_data_recs4 IS TABLE OF BR_NOTES.note_seq%TYPE;
  TYPE v_data_recs5 IS TABLE OF BR_NOTES.text%TYPE;
  TYPE v_data_recs6 IS TABLE OF BR_NOTES.intl_ref%TYPE;
  l_data_recs1 v_data_recs1;
  l_data_recs2 v_data_recs2;
  l_data_recs3 v_data_recs3;
  l_data_recs4 v_data_recs4;
  l_data_recs5 v_data_recs5;
  l_data_recs6 v_data_recs6;



  BEGIN

    IF p_eventLogTiming = 1
    THEN
      v_startTime := sysdate;
    END IF;

    --
    -- Set the range of records to be processed
    --

    v_begRecordRange := g_min_record_id;
    v_endRecordRange := g_min_record_id + p_purgeBlockSize;
    --

    IF p_deleteReturnsRows = 1 THEN
      file_id4 := UTL_FILE.FOPEN(p_PurgeFilesDir,v_file_name,'a',32767);

      SELECT acct_name
      INTO l_acct_name
      FROM BS_ACCTS
      WHERE acct_id = p_acctid;

      l_str := p_timestamp||chr(127)||'br_notes'||chr(127)||p_version||chr(127)||to_char(p_acctid)||chr(127)||l_acct_name;

      UTL_FILE.PUT_LINE(file_id4, l_str);

      l_str := 'ACCT_ID'||chr(127)||
               'NOTE_ID'||chr(127)||
               'NOTE_GROUP'||chr(127)||
               'NOTE_SEQ'||chr(127)||
               'TEXT'||chr(127)||
               'INTL_REF';

      UTL_FILE.PUT_LINE(file_id4, l_str);

    END IF;

    WHILE (v_begRecordRange <= g_maxAuditId)
    LOOP

      EXECUTE IMMEDIATE 'DELETE FROM br_notes bn '||
                     'WHERE (bn.acct_id,bn.note_group) IN (SELECT tp.acct_id, tp.note_group FROM '||p_tempTableName||' tp '||
                     '                                     WHERE tp.acct_id = :1 '||
                     '                                     AND   tp.record_id BETWEEN :2 and :3 ) '||
                     ' AND bn.note_group > 0 '||
                     ' returning bn.ACCT_ID,bn.NOTE_ID,bn.NOTE_GROUP,bn.NOTE_SEQ,bn.TEXT,bn.INTL_REF into
                               :4,:5,:6,:7,:8,:9 '
      using p_acctId,v_begRecordRange,v_endRecordRange RETURNING BULK COLLECT INTO
        l_data_recs1,
        l_data_recs2,
        l_data_recs3,
        l_data_recs4,
        l_data_recs5,
        l_data_recs6;

      IF l_data_recs1.count > 0 THEN

        v_tot_rows_processed := v_tot_rows_processed + l_data_recs1.count;

        IF p_deleteReturnsRows = 1 THEN

          FOR indx IN l_data_recs1.first .. l_data_recs1.last
          LOOP
            l_str :=
              to_char(l_data_recs1(indx))||chr(127)||
              to_char(l_data_recs2(indx))||chr(127)||
              to_char(l_data_recs3(indx))||chr(127)||
              to_char(l_data_recs4(indx))||chr(127)||
              l_data_recs5(indx)||chr(127)||
              l_data_recs6(indx);

            replace_tab_cr_line_feed(l_str);

            UTL_FILE.PUT_LINE(file_id4, l_str);
          END LOOP;
        END IF;
      END IF;

      COMMIT;

      --
      -- increment the variables for the record range to be processed in the next loop
      --
      v_begRecordRange := v_endRecordRange + 1;
      v_endRecordRange := v_endRecordRange + p_purgeBlockSize;

    END LOOP;

    COMMIT;

    IF p_deleteReturnsRows = 1 THEN
      UTL_FILE.FCLOSE(file_id4);
      file_id4.ID := NULL;
    END IF;

    IF p_eventLogTiming = 1
    THEN
      v_endTime := sysdate;
      v_timeDiff := (v_endTime - v_startTime) * 86400;  -- time given in seconds

      Pkg_Bs_Log_Event.pr_log_timing(p_instance_id => 0
                                    ,p_program_id => 11
                                    ,p_message => 'Note group purged: '||to_char(v_tot_rows_processed)||' rows deleted.'
                                    ,p_extra_text => 'Duration: '||to_char(v_timeDiff)||' seconds'
                                    ,p_category_id => 1
                                    ,p_success => v_success);
    END IF;

    v_success := 1;
    p_success := v_success;

    EXCEPTION
    WHEN OTHERS THEN

    IF p_deleteReturnsRows = 1 THEN
        UTL_FILE.FCLOSE(file_id4);
        file_id4.ID := NULL;
    END IF;

       p_errReason := 'pr_purge_note_group';
       Pkg_Bs_Log_Event.pr_log_error (p_instance_id => 0
                                     ,p_severity_id => 0
                                     ,p_message => 'Error calling pkg_br_purge.pr_purge_note_group'
                                     ,p_extra_text => 'Server Error '||to_char(SQLCODE)||' '||SQLERRM
                                     ,p_category_id => 1
                                     ,p_success => v_success
                                     );
    p_success := 0;                  -- calling program needs to know exception raised

  END pr_purge_note_group;


  /* ****************************************************************************
   Name:    pr_purge_holding_notes
   Date:    31-Mar-2006
   Author:  S.Mace

   Purpose: This procedure is part of the text purge routine and deletes
            br_notes for a holdings account.

            The activity may optionally be timed and the result put into the bs_event_log table.

   Change History
   --------------
   Date     Author              Description of change
   ----     ------              ---------------------
  *****************************************************************************/
   PROCEDURE pr_purge_holding_notes(p_acctId            IN INTEGER := 0
                                   ,p_eventLogTiming    IN INTEGER := 0
                                   ,p_timestamp         IN VARCHAR2
                                   ,p_version           IN VARCHAR2
                                   ,p_deleteReturnsRows IN INTEGER := 0
                                   ,p_purgeFilesDir     IN VARCHAR2
                                   ,p_success           OUT INTEGER
                                   ,p_errReason         OUT VARCHAR2
                                   )
  IS
  v_rows_processed INTEGER;
  v_success        INTEGER := 0; -- defaulted to failure
  v_timeDiff       INTEGER := 0;
  v_cursor_name    INTEGER;
  v_startTime      DATE;
  v_endTime        DATE;
  file_id5         UTL_FILE.FILE_TYPE;
  l_str            VARCHAR2(5000);
  l_acct_name      VARCHAR2(255);
  v_file_name     VARCHAR2(40) := p_timestamp||'_'||to_char(p_acctid)||'_'||'br_notes.txt';

  TYPE v_data_recs1 IS TABLE OF BR_NOTES.acct_id%TYPE;
  TYPE v_data_recs2 IS TABLE OF BR_NOTES.note_id%TYPE;
  TYPE v_data_recs3 IS TABLE OF BR_NOTES.note_group%TYPE;
  TYPE v_data_recs4 IS TABLE OF BR_NOTES.note_seq%TYPE;
  TYPE v_data_recs5 IS TABLE OF BR_NOTES.text%TYPE;
  TYPE v_data_recs6 IS TABLE OF BR_NOTES.intl_ref%TYPE;
  l_data_recs1 v_data_recs1;
  l_data_recs2 v_data_recs2;
  l_data_recs3 v_data_recs3;
  l_data_recs4 v_data_recs4;
  l_data_recs5 v_data_recs5;
  l_data_recs6 v_data_recs6;

  BEGIN
    IF p_eventLogTiming = 1 THEN
      v_startTime := sysdate;
    END IF;
    --
    -- prepare to purge notes records
    --
    if (p_deleteReturnsRows = 1) then
        file_id5 := UTL_FILE.FOPEN(p_PurgeFilesDir,v_file_name,'a',32767);
    end if;

    delete from br_notes bn
          where bn.acct_id = p_acctid
            and bn.note_id in(
                    select distinct bra.note_id
                               from br_audit bra
                              where bra.acct_id = bn.acct_id
                                and bra.sequence_num < g_sequence_num
                                and bra.type = 8)
            and bn.intl_ref != ' '
    returning bn.acct_id, bn.note_id, bn.note_group, bn.note_seq
             ,bn.text, bn.intl_ref
    bulk collect into l_data_recs1, l_data_recs2, l_data_recs3, l_data_recs4
                     ,l_data_recs5, l_data_recs6;

    IF l_data_recs1.count > 0 THEN
      v_rows_processed := v_rows_processed + l_data_recs1.count;

      IF p_deleteReturnsRows = 1 THEN
        FOR indx IN l_data_recs1.first .. l_data_recs1.last
        LOOP
          l_str :=
            to_char(l_data_recs1(indx))||chr(127)||
            to_char(l_data_recs2(indx))||chr(127)||
            to_char(l_data_recs3(indx))||chr(127)||
            to_char(l_data_recs4(indx))||chr(127)||
            l_data_recs5(indx)||chr(127)||
            l_data_recs6(indx);

          replace_tab_cr_line_feed(l_str);

          UTL_FILE.PUT_LINE(file_id5, l_str);
        END LOOP;

        IF p_deleteReturnsRows = 1 THEN
          UTL_FILE.FCLOSE(file_id5);
          file_id5.ID := NULL;
        END IF;
      END IF;
    END IF;


    COMMIT;

    IF p_eventLogTiming = 1
    THEN
      v_endTime := sysdate;

      v_timeDiff := (v_endTime - v_startTime) * 86400;  -- time given in seconds

      Pkg_Bs_Log_Event.pr_log_timing(p_instance_id => 0
                                    ,p_program_id => 11
                                    ,p_message => 'Holding notes purged: '||to_char(v_rows_processed)||' rows deleted.'
                                    ,p_extra_text => 'Duration: '||to_char(v_timeDiff)||' seconds'
                                    ,p_category_id => 1
                                    ,p_success => v_success);
    END IF;

    v_success := 1;
    p_success := v_success;


  EXCEPTION
  WHEN OTHERS THEN
    IF p_deleteReturnsRows = 1 THEN
      UTL_FILE.FCLOSE(file_id5);
      file_id5.ID := NULL;
    END IF;

    p_errReason := 'pr_purge_holding_notes';
    Pkg_Bs_Log_Event.pr_log_error (p_instance_id => 0
                                  ,p_severity_id => 0
                                  ,p_message => 'Error calling pkg_br_purge.pr_purge_holding_notes'
                                  ,p_extra_text => 'Server Error '||to_char(SQLCODE)||' '||SQLERRM
                                  ,p_category_id => 1
                                  ,p_success => v_success
                                  );
    p_success := 0;                  -- calling program needs to know exception raised
  END pr_purge_holding_notes;


  /*****************************************************************************
   Name:    pr_purge_holding_audits
   Date:    31-Mar-2006
   Author:  S.Mace
   Purpose: This procedure is part of the text purge routine and deletes the
            br_audit records for a holding account.

            The activity may optionally be timed and the result put into the bs_event_log table.

   Change History
   --------------
   Date     Author              Description of change
   ----     ------              ---------------------
   20-08-07 S.Mace              Replaced p_maxAuditId with use of g_sequence_num for 2.12.1 AS_IDs work.
  *****************************************************************************/

  procedure pr_purge_holding_audits(p_acctId          IN INTEGER := 0
                                   ,p_eventLogTiming  IN INTEGER := 0
                                   ,p_success         OUT INTEGER
                                   ,p_errReason       OUT VARCHAR2
                                   )
  is
    v_rows_processed INTEGER;
    v_success        INTEGER := 0; -- defaulted to failure
    v_timeDiff       INTEGER := 0;

    v_startTime      DATE;
    v_endTime        DATE;
  BEGIN

    IF p_eventLogTiming = 1
    THEN
      v_startTime := sysdate;
    END IF;

    delete from br_audit bra
          where bra.acct_id = p_acctid
            and bra.sequence_num < g_sequence_num
            and bra.type = 8;

    v_rows_processed := sql%rowcount;

    commit;

    IF p_eventLogTiming = 1
    THEN
      v_endTime := sysdate;
      v_timeDiff := (v_endTime - v_startTime) * 86400;  -- time given in seconds

      pkg_bs_log_event.pr_log_timing(p_instance_id => 0
                                    ,p_program_id => 11
                                    ,p_message => 'Holding audits purged '||to_char(v_rows_processed)||' rows deleted.'
                                    ,p_extra_text => 'Duration: '||to_char(v_timeDiff)||' seconds'
                                    ,p_category_id => 1
                                    ,p_success => v_success);
    END IF;

    v_success := 1;
    p_success := v_success;


  exception
      when others then
         p_errReason := 'pr_purge_holding_audits';
         pkg_bs_log_event.pr_log_error (p_instance_id => 0
                                       ,p_severity_id => 0
                                       ,p_message => 'Error calling pkg_br_purge.pr_purge_holding_audits'
                                       ,p_extra_text => 'Server Error '||to_char(SQLCODE)||' '||SQLERRM
                                       ,p_category_id => 1
                                       ,p_success => v_success
                                       );
         p_success := 0;                  -- calling program needs to know exception raised
  END pr_purge_holding_audits;


   /* ****************************************************************************
   Name:    pr_purge_checkpoint_audits
   Date:    31-Mar-2006
   Author:  S.Mace
   Purpose: This procedure is part of the text purge routine and deletes the
            br_audit records associated with checkpoints for an account.

            The activity may optionally be timed and the result put into the bs_event_log table.

   Change History
   --------------
   Date     Author              Description of change
   ----     ------              ---------------------
   20-08-07 S.Mace              Replaced p_maxAuditId with use of g_sequence_num for 2.12.1 AS_IDs work.
   05-09-07 S.Perrett           Changed delete returning output to file, to a select returning output
                                to file ordered by sequence_num, then added extra delete statement (this
                                was done as delete can't rpoduce ordered output)

  *****************************************************************************/
  PROCEDURE pr_purge_checkpoint_audits(p_acctId            IN INTEGER := 0
                                      ,p_eventLogTiming    IN INTEGER := 0
                                      ,p_timestamp         IN VARCHAR2
                                      ,p_version           IN VARCHAR2
                                      ,p_deleteReturnsRows IN INTEGER := 0
                                      ,p_purgeFilesDir     IN VARCHAR2
                                      ,p_success           OUT INTEGER
                                      ,p_errReason         OUT VARCHAR2
                                      )

  IS

  v_rows_processed INTEGER;
  v_success        INTEGER := 0; -- defaulted to failure
  v_timeDiff       INTEGER := 0;

  v_cursor_name    INTEGER;
  v_startTime      DATE;
  v_endTime        DATE;
  file_id7         UTL_FILE.FILE_TYPE;
  l_str            VARCHAR2(5000);
  l_acct_name      VARCHAR2(255);
  v_file_name        VARCHAR2(40) := p_timestamp||'_'||to_char(p_acctid)||'_'||'br_audit.txt';

  type v_data_recs1 is table of br_audit.acct_id%type;
  type v_data_recs2 is table of br_audit.audit_id%type;
  type v_data_recs3 is table of br_audit.type%type;
  type v_data_recs4 is table of br_audit.timestamp%type;
  type v_data_recs5 is table of br_audit.cs_flag%type;
  type v_data_recs6 is table of br_audit.record_id%type;
  type v_data_recs7 is table of br_audit.user_id%type;
  type v_data_recs8 is table of br_audit.bfr_state%type;
  type v_data_recs9 is table of br_audit.aft_state%type;
  type v_data_recs10 is table of br_audit.note_id%type;
  type v_data_recs11 is table of br_audit.orig_id%type;
  type v_data_recs12 is table of br_audit.bfr_date%type;
  type v_data_recs13 is table of br_audit.aft_date%type;
  type v_data_recs14 is table of br_audit.whichone%type;
  type v_data_recs15 is table of br_audit.recmethod%type;
  type v_data_recs16 is table of br_audit.bfr_amt%type;
  type v_data_recs17 is table of br_audit.aft_amt%type;
  type v_data_recs18 is table of br_audit.num_in_grp%type;
  type v_data_recs19 is table of br_audit.pass_id%type;
  type v_data_recs20 is table of br_audit.spare_one%type;
  type v_data_recs21 is table of br_audit.spare_two%type;
  type v_data_recs22 is table of br_audit.sequence_num%type;

  l_data_recs1 v_data_recs1;
  l_data_recs2 v_data_recs2;
  l_data_recs3 v_data_recs3;
  l_data_recs4 v_data_recs4;
  l_data_recs5 v_data_recs5;
  l_data_recs6 v_data_recs6;
  l_data_recs7 v_data_recs7;
  l_data_recs8 v_data_recs8;
  l_data_recs9 v_data_recs9;
  l_data_recs10 v_data_recs10;
  l_data_recs11 v_data_recs11;
  l_data_recs12 v_data_recs12;
  l_data_recs13 v_data_recs13;
  l_data_recs14 v_data_recs14;
  l_data_recs15 v_data_recs15;
  l_data_recs16 v_data_recs16;
  l_data_recs17 v_data_recs17;
  l_data_recs18 v_data_recs18;
  l_data_recs19 v_data_recs19;
  l_data_recs20 v_data_recs20;
  l_data_recs21 v_data_recs21;
  l_data_recs22 v_data_recs22;



  BEGIN
    IF p_eventLogTiming = 1
    THEN
      v_startTime := sysdate;
    END IF;

    IF p_deleteReturnsRows = 1 THEN
      file_id7 := UTL_FILE.FOPEN(p_PurgeFilesDir,v_file_name,'a',32767);
    END IF;

    select   acct_id, audit_id, type, timestamp, cs_flag
            ,record_id, user_id, bfr_state, aft_state, note_id
            ,orig_id, bfr_date, aft_date, whichone
            ,recmethod, bfr_amt, aft_amt, num_in_grp
            ,pass_id, spare_one, spare_two, sequence_num
    bulk collect into l_data_recs1, l_data_recs2, l_data_recs3, l_data_recs4, l_data_recs5
            ,l_data_recs6, l_data_recs7, l_data_recs8, l_data_recs9, l_data_recs10
            ,l_data_recs11, l_data_recs12, l_data_recs13, l_data_recs14
            ,l_data_recs15, l_data_recs16, l_data_recs17, l_data_recs18
            ,l_data_recs19, l_data_recs20, l_data_recs21, l_data_recs22
        from br_audit bra
       where bra.acct_id = p_acctid
         and bra.sequence_num < g_sequence_num
         and bra.type in(1, 7)
    order by bra.sequence_num;

    IF l_data_recs1.count > 0 THEN
      v_rows_processed := v_rows_processed + l_data_recs1.count;

      IF p_deleteReturnsRows = 1 THEN
        FOR indx IN l_data_recs1.first .. l_data_recs1.last
        LOOP
          l_str :=
            to_char(l_data_recs1(indx))||chr(127)||
            to_char(l_data_recs2(indx))||chr(127)||
            to_char(l_data_recs3(indx))||chr(127)||
            to_char(l_data_recs4(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
            l_data_recs5(indx)||chr(127)||
            to_char(l_data_recs6(indx))||chr(127)||
            to_char(l_data_recs7(indx))||chr(127)||
            to_char(l_data_recs8(indx))||chr(127)||
            to_char(l_data_recs9(indx))||chr(127)||
            to_char(l_data_recs10(indx))||chr(127)||
            to_char(l_data_recs11(indx))||chr(127)||
            to_char(l_data_recs12(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
            to_char(l_data_recs13(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
            to_char(l_data_recs14(indx))||chr(127)||
            to_char(l_data_recs15(indx))||chr(127)||
            to_char(l_data_recs16(indx))||chr(127)||
            to_char(l_data_recs17(indx))||chr(127)||
            to_char(l_data_recs18(indx))||chr(127)||
            to_char(l_data_recs19(indx))||chr(127)||
            to_char(l_data_recs20(indx))||chr(127)||
            to_char(l_data_recs21(indx));
   -- NOT OUTPUTING SEQUENCE_NUM         TO_CHAR(l_data_recs22(indx));

          replace_tab_cr_line_feed(l_str);

          UTL_FILE.PUT_LINE(file_id7, l_str);
        END LOOP;

        IF p_deleteReturnsRows = 1 THEN
          UTL_FILE.FCLOSE(file_id7);
          file_id7.ID := NULL;
        END IF;

      END IF;
    END IF;

    delete from br_audit bra
          where bra.acct_id = p_acctid
            and bra.sequence_num < g_sequence_num
            and bra.type in(1, 7);

    commit;

    IF p_eventLogTiming = 1
    THEN
      v_endTime := sysdate;
      v_timeDiff := (v_endTime - v_startTime) * 86400;  -- time given in seconds

      Pkg_Bs_Log_Event.pr_log_timing(p_instance_id => 0
                                    ,p_program_id => 11
                                    ,p_message => 'checkpoint audits purged: '||to_char(v_rows_processed)||' rows deleted.'
                                    ,p_extra_text => 'Duration: '||to_char(v_timeDiff)||' seconds'
                                    ,p_category_id => 1
                                    ,p_success => v_success);
    END IF;

    v_success := 1;
    p_success := v_success;

  EXCEPTION
  WHEN OTHERS THEN
    IF p_deleteReturnsRows = 1 THEN
      UTL_FILE.FCLOSE(file_id7);
      file_id7.ID := NULL;
    END IF;
    p_errReason := 'pr_purge_checkpoint_audits';
    Pkg_Bs_Log_Event.pr_log_error (p_instance_id => 0
                                  ,p_severity_id => 0
                                  ,p_message => 'Error calling pkg_br_purge.pr_purge_checkpoint_audits'
                                  ,p_extra_text => 'Server Error '||to_char(SQLCODE)||' '||SQLERRM
                                  ,p_category_id => 1
                                  ,p_success => v_success
                                  );
    p_success := 0;                  -- calling program needs to know exception raised
  END pr_purge_checkpoint_audits;

  /* ****************************************************************************
   Name:    pr_purge_checkpoints
   Date:    31-Mar-2006
   Author:  S.Mace
   Purpose: This procedure is part of the text purge routine and deletes the
            br_check records for an account.

            The activity may optionally be timed and the result put into the bs_event_log table.

   Change History
   --------------
   Date     Author              Description of change
   ----     ------              ---------------------
   20-08-07 S.Mace              Replaced p_maxAuditId with use of g_sequence_num for 2.12.1 AS_IDs work.
   05-09-07 S.Perrett           Changed delete returning output to file, to a select returning output
                                to file ordered by sequence_num, then added extra delete statement (this
                                was done as delete can't rpoduce ordered output)
   14-09-07 S.Perrett           Defect 14081 fixed

  *****************************************************************************/

  PROCEDURE pr_purge_checkpoints(p_acctId            IN INTEGER := 0
                                ,p_eventLogTiming    IN INTEGER := 0
                                ,p_timestamp         IN VARCHAR2
                                ,p_version           IN VARCHAR2
                                ,p_deleteReturnsRows IN INTEGER := 0
                                ,p_purgeFilesDir     IN VARCHAR2
                                ,p_success           OUT INTEGER
                                ,p_errReason         OUT VARCHAR2
                                )
  IS
  v_rows_processed INTEGER;
  v_success        INTEGER := 0; -- defaulted to failure
  v_timeDiff       INTEGER := 0;
  v_startTime      DATE;

  v_endTime        DATE;
  file_id16        UTL_FILE.FILE_TYPE;
  l_str            VARCHAR2(5000);
  l_acct_name      VARCHAR2(255);
  v_file_name     VARCHAR2(40) := p_timestamp||'_'||to_char(p_acctid)||'_'||'br_check.txt';

  TYPE v_data_recs1 IS TABLE OF BR_CHECK.acct_id%TYPE;
  TYPE v_data_recs2 IS TABLE OF BR_CHECK.audit_id%TYPE;
  TYPE v_data_recs3 IS TABLE OF BR_CHECK.s_bal%TYPE;
  TYPE v_data_recs4 IS TABLE OF BR_CHECK.c_bal%TYPE;
  TYPE v_data_recs5 IS TABLE OF BR_CHECK.s_o_pay%TYPE;
  TYPE v_data_recs6 IS TABLE OF BR_CHECK.s_o_rcv%TYPE;
  TYPE v_data_recs7 IS TABLE OF BR_CHECK.c_o_pay%TYPE;
  TYPE v_data_recs8 IS TABLE OF BR_CHECK.c_o_rcv%TYPE;
  TYPE v_data_recs9 IS TABLE OF BR_CHECK.description%TYPE;
  TYPE v_data_recs10 IS TABLE OF BR_CHECK.chktype%TYPE;
  TYPE v_data_recs11 IS TABLE OF BR_CHECK.ld_num_p%TYPE;
  TYPE v_data_recs12 IS TABLE OF BR_CHECK.ld_num_r%TYPE;
  TYPE v_data_recs13 IS TABLE OF BR_CHECK.ld_amt_p%TYPE;
  TYPE v_data_recs14 IS TABLE OF BR_CHECK.ld_amt_r%TYPE;
  TYPE v_data_recs15 IS TABLE OF BR_CHECK.cs_flag%TYPE;
  TYPE v_data_recs16 IS TABLE OF BR_CHECK.ld_inst%TYPE;
  TYPE v_data_recs17 IS TABLE OF BR_CHECK.checksum%TYPE;
  TYPE v_data_recs18 IS TABLE OF BR_CHECK.num_sop%TYPE;
  TYPE v_data_recs19 IS TABLE OF BR_CHECK.num_sor%TYPE;
  TYPE v_data_recs20 IS TABLE OF BR_CHECK.num_cop%TYPE;
  TYPE v_data_recs21 IS TABLE OF BR_CHECK.num_cor%TYPE;
  TYPE v_data_recs22 IS TABLE OF BR_CHECK.sequence_num%TYPE;

  l_data_recs1 v_data_recs1;
  l_data_recs2 v_data_recs2;
  l_data_recs3 v_data_recs3;
  l_data_recs4 v_data_recs4;
  l_data_recs5 v_data_recs5;
  l_data_recs6 v_data_recs6;
  l_data_recs7 v_data_recs7;
  l_data_recs8 v_data_recs8;
  l_data_recs9 v_data_recs9;
  l_data_recs10 v_data_recs10;
  l_data_recs11 v_data_recs11;
  l_data_recs12 v_data_recs12;
  l_data_recs13 v_data_recs13;
  l_data_recs14 v_data_recs14;
  l_data_recs15 v_data_recs15;
  l_data_recs16 v_data_recs16;
  l_data_recs17 v_data_recs17;
  l_data_recs18 v_data_recs18;
  l_data_recs19 v_data_recs19;
  l_data_recs20 v_data_recs20;
  l_data_recs21 v_data_recs21;
  l_data_recs22 v_data_recs22;

  BEGIN
    IF p_eventLogTiming = 1
    THEN
      v_startTime := sysdate;
    END IF;

    IF p_deleteReturnsRows = 1 THEN
      file_id16 := UTL_FILE.FOPEN(p_PurgeFilesDir,v_file_name,'a',32767);

      select acct_name
        into l_acct_name
        from bs_accts
       where acct_id = p_acctid;

      l_str := p_timestamp||chr(127)||'br_check'||chr(127)||p_version||chr(127)||to_char(p_acctid)||chr(127)||l_acct_name;

      UTL_FILE.PUT_LINE(file_id16, l_str);

      l_str := 'ACCT_ID'||chr(127)||
               'AUDIT_ID'||chr(127)||
               'S_BAL'||chr(127)||
               'C_BAL'||chr(127)||
               'S_O_PAY'||chr(127)||
               'S_O_RCV'||chr(127)||
               'C_O_PAY'||chr(127)||
               'C_O_RCV'||chr(127)||
               'DESCRIPTION'||chr(127)||
               'CHKTYPE'||chr(127)||
               'LD_NUM_P'||chr(127)||
               'LD_NUM_R'||chr(127)||
               'LD_AMT_P'||chr(127)||
               'LD_AMT_R'||chr(127)||
               'CS_FLAG'||chr(127)||
               'LD_INST'||chr(127)||
               'CHECKSUM'||chr(127)||
               'NUM_SOP'||chr(127)||
               'NUM_SOR'||chr(127)||
               'NUM_COP'||chr(127)||
               'NUM_COR'||chr(127)||
               'SEQUENCE_NUM';

      UTL_FILE.PUT_LINE(file_id16, l_str);

    END IF;

    select   acct_id, audit_id, s_bal, c_bal, s_o_pay
            ,s_o_rcv, c_o_pay, c_o_rcv, description, chktype
            ,ld_num_p, ld_num_r, ld_amt_p, ld_amt_r
            ,cs_flag, ld_inst, checksum, num_sop
            ,num_sor, num_cop, num_cor, sequence_num
    bulk collect into l_data_recs1, l_data_recs2, l_data_recs3, l_data_recs4, l_data_recs5
            ,l_data_recs6, l_data_recs7, l_data_recs8, l_data_recs9, l_data_recs10
            ,l_data_recs11, l_data_recs12, l_data_recs13, l_data_recs14
            ,l_data_recs15, l_data_recs16, l_data_recs17, l_data_recs18
            ,l_data_recs19, l_data_recs20, l_data_recs21, l_data_recs22
        from br_check
       where acct_id = p_acctid
         and sequence_num <
                 (select brc.sequence_num
                    from br_check brc, br_audit bra
                   where bra.acct_id = p_acctid
                     and bra.acct_id = brc.acct_id
                     and bra.audit_id = brc.audit_id
                     and bra.sequence_num = g_sequence_num)
    order by sequence_num;

    IF l_data_recs1.count > 0 THEN
      v_rows_processed := v_rows_processed + l_data_recs1.count;

      IF p_deleteReturnsRows = 1 THEN
      FOR indx IN l_data_recs1.first .. l_data_recs1.last
      LOOP
        l_str :=
          to_char(l_data_recs1(indx))||chr(127)||
          to_char(l_data_recs2(indx))||chr(127)||
          to_char(l_data_recs3(indx))||chr(127)||
          to_char(l_data_recs4(indx))||chr(127)||
          to_char(l_data_recs5(indx))||chr(127)||
          to_char(l_data_recs6(indx))||chr(127)||
          to_char(l_data_recs7(indx))||chr(127)||
          to_char(l_data_recs8(indx))||chr(127)||
          l_data_recs9(indx)||chr(127)||
          to_char(l_data_recs10(indx))||chr(127)||
          to_char(l_data_recs11(indx))||chr(127)||
          to_char(l_data_recs12(indx))||chr(127)||
          to_char(l_data_recs13(indx))||chr(127)||
          to_char(l_data_recs14(indx))||chr(127)||
          l_data_recs15(indx)||chr(127)||
          to_char(l_data_recs16(indx))||chr(127)||
          l_data_recs17(indx)||chr(127)||
          to_char(l_data_recs18(indx))||chr(127)||
          to_char(l_data_recs19(indx))||chr(127)||
          to_char(l_data_recs20(indx))||chr(127)||
          to_char(l_data_recs21(indx));
    -- NOT OUTPUTING SEQUENCE_NUM      TO_CHAR(l_data_recs22(indx));

        replace_tab_cr_line_feed(l_str);

        UTL_FILE.PUT_LINE(file_id16, l_str);
      END LOOP;

      IF p_deleteReturnsRows = 1 THEN
         UTL_FILE.FCLOSE(file_id16);
         file_id16.ID := NULL;
      END IF;

    END IF;
  END IF;

  delete from br_check
          where acct_id = p_acctid
            and sequence_num <
                    (select brc.sequence_num
                       from br_check brc, br_audit bra
                      where bra.acct_id = p_acctid
                        and bra.acct_id = brc.acct_id
                        and bra.audit_id = brc.audit_id
                        and bra.sequence_num = g_sequence_num);

  commit;

  IF p_eventLogTiming = 1 THEN
    v_endTime := sysdate;
    v_timeDiff := (v_endTime - v_startTime) * 86400;  -- time given in seconds

    Pkg_Bs_Log_Event.pr_log_timing(p_instance_id => 0
                                  ,p_program_id => 11
                                  ,p_message => 'Checkpoints purged '||to_char(v_rows_processed)||' rows deleted.'
                                  ,p_extra_text => 'Duration: '||to_char(v_timeDiff)||' seconds'
                                  ,p_category_id => 1
                                  ,p_success => v_success);
  END IF;

  v_success := 1;
  p_success := v_success;


  EXCEPTION
  WHEN OTHERS THEN
    IF p_deleteReturnsRows = 1 THEN
       UTL_FILE.FCLOSE(file_id16);
          file_id16.ID := NULL;
    END IF;

    p_errReason := 'pr_purge_checkpoints';
    Pkg_Bs_Log_Event.pr_log_error (p_instance_id => 0
                                  ,p_severity_id => 0
                                  ,p_message => 'Error calling pkg_br_purge.pr_purge_checkpoints'
                                  ,p_extra_text => 'Server Error '||to_char(SQLCODE)||' '||SQLERRM
                                  ,p_category_id => 1
                                  ,p_success => v_success
                                  );
    p_success := 0;                  -- calling program needs to know exception raised

  END pr_purge_checkpoints;


   /*****************************************************************************

   Name:    pr_purge_feed_audits
   Date:    31-Mar-2006
   Author:  S.Mace
   Purpose: This procedure is part of the text purge routine and deletes the
            br_audits records for the feed start audits associated with an account.

            The activity may optionally be timed and the result put into the bs_event_log table.

   Change History
   --------------
   Date     Author              Description of change
   ----     ------              ---------------------
   20-08-07 S.Mace              Replaced p_maxAuditId with use of g_sequence_num for 2.12.1 AS_IDs work.

  *****************************************************************************/


  PROCEDURE pr_purge_feed_audits(p_acctId    IN INTEGER := 0
                                ,p_eventLogTiming  IN INTEGER := 0
                                ,p_success        OUT INTEGER
                                ,p_errReason      OUT VARCHAR2
                                )
  IS
    v_rows_processed INTEGER;
    v_success        INTEGER := 0; -- defaulted to failure
    v_cursor_name    INTEGER;
    v_timeDiff       INTEGER := 0;

    v_startTime      DATE;
    v_endTime        DATE;
  BEGIN
    IF p_eventLogTiming = 1
    THEN
      v_startTime := sysdate;
    END IF;

    delete from br_audit bra
          where bra.acct_id = p_acctid
            and bra.type = 18
            and bra.sequence_num < g_sequence_num
            and not exists(
                    select 1
                      from br_data brd
                     where brd.acct_id = bra.acct_id
                       and brd.load_id = bra.whichone
                       and brd.load_id <> 0);

    v_rows_processed := sql%rowcount;

    commit;

    IF p_eventLogTiming = 1
    THEN
      v_endTime := sysdate;
      v_timeDiff := (v_endTime - v_startTime) * 86400;  -- time given in seconds

      pkg_bs_log_event.pr_log_timing(p_instance_id => 0
                                    ,p_program_id => 11
                                    ,p_message => 'Feed audits purged: '||to_char(v_rows_processed)||' rows deleted.'
                                    ,p_extra_text => 'Duration: '||to_char(v_timeDiff)||' seconds'
                                    ,p_category_id => 1
                                    ,p_success => v_success);
    END IF;


    v_success := 1;
    p_success := v_success;

  EXCEPTION
  WHEN OTHERS THEN
    p_errReason := 'pr_purge_feed_audits';
    Pkg_Bs_Log_Event.pr_log_error (p_instance_id => 0
                                  ,p_severity_id => 0
                                  ,p_message => 'Error calling pkg_br_purge.pr_purge_feed_audits'
                                  ,p_extra_text => 'Server Error '||to_char(SQLCODE)||' '||SQLERRM
                                  ,p_category_id => 1
                                  ,p_success => v_success
                                  );

    p_success := 0;                  -- calling program needs to know exception raised
  END pr_purge_feed_audits;

   /*****************************************************************************
   Name:    pr_purge_periods_outstanding
   Date:    31-Mar-2006
   Author:  S.Mace
   Purpose: This procedure is part of the text purge routine and deletes the
            br_pout reords for outstanding periods associated with an account.

            The activity may optionally be timed and the result put into the bs_event_log table.

   Change History

   --------------
   Date     Author              Description of change
   ----     ------              ---------------------
   20-08-07 S.Mace              Replaced p_maxAuditId with use of g_sequence_num for 2.12.1 AS_IDs work.

  *****************************************************************************/
  PROCEDURE pr_purge_periods_outstanding(p_acctId    IN INTEGER := 0
                                        ,p_eventLogTiming  IN INTEGER := 0
                                        ,p_success        OUT INTEGER
                                        ,p_errReason      OUT VARCHAR2
                                        )
  IS
    v_rows_processed INTEGER;

    v_success        INTEGER := 0; -- defaulted to failure
    v_timeDiff       INTEGER := 0;
    v_startTime      DATE;
    v_endTime        DATE;
  BEGIN

    IF p_eventLogTiming = 1
    THEN
      v_startTime := sysdate;
    END IF;

    delete from br_pout bp
          where bp.link_period_id in(
                    select p1.per_id
                      from br_periods p1
                     where p1.acct_id = p_acctid
                       and p1.period in (
                               select p2.period
                                 from br_periods p2
                                where p2.acct_id = p1.acct_id
                                  and p2.state in(1, 2)
                                  and p2.per_id not in(
                                          select distinct a.record_id
                                                     from br_audit a
                                                    where a.acct_id = p2.acct_id
                                                      and a.sequence_num < g_sequence_num
                                                      and a.type in(10, 11, 12)))
                       and p1.period not in (
                               select distinct d.period
                                          from br_data d
                                         where d.acct_id = p1.acct_id
                                           and d.state <> 6
                                           and d.period in(
                                                   select p3.period
                                                     from br_periods p3
                                                    where p3.acct_id = d.acct_id
                                                      and p3.state in(1, 2)
                                                      and p3.per_id not in(
                                                              select distinct a2.record_id
                                                                         from br_audit a2
                                                                        where a2.acct_id =
                                                                                  p3.acct_id
                                                                          and a2.sequence_num < g_sequence_num
                                                                          and a2.type in (10, 11, 12)))));

    v_rows_processed := sql%rowcount;

    commit;


    IF p_eventLogTiming = 1
    THEN
      v_endTime := sysdate;
      v_timeDiff := (v_endTime - v_startTime) * 86400;  -- time given in seconds

      Pkg_Bs_Log_Event.pr_log_timing(p_instance_id => 0
                                    ,p_program_id => 11
                                    ,p_message => 'Periods outstanding purged: '||to_char(v_rows_processed)||' rows deleted.'
                                    ,p_extra_text => 'Duration: '||to_char(v_timeDiff)||' seconds'
                                    ,p_category_id => 1
                                    ,p_success => v_success);
    END IF;


    v_success := 1;
    p_success := v_success;


  EXCEPTION
  WHEN OTHERS THEN
    p_errReason := 'pr_purge_periods_outstanding';
    Pkg_Bs_Log_Event.pr_log_error (p_instance_id => 0
                                  ,p_severity_id => 0
                                  ,p_message => 'Error calling pkg_br_purge.pr_purge_periods_outstanding'
                                  ,p_extra_text => 'Server Error '||to_char(SQLCODE)||' '||SQLERRM
                                  ,p_category_id => 1
                                  ,p_success => v_success
                                  );
    p_success := 0;                  -- calling program needs to know exception raised
  END pr_purge_periods_outstanding;

   /*****************************************************************************
   Name:    pr_purge_closed_periods
   Date:    31-Mar-2006
   Author:  S.Mace
   Purpose: This procedure is part of the text purge routine and deletes the
            br_periods records for closed or deleted periods associated with an account.

            The activity may optionally be timed and the result put into the bs_event_log table.


   Change History
   --------------
   Date     Author              Description of change
   ----     ------              ---------------------
   20-08-07 S.Mace              Replaced p_maxAuditId with use of g_sequence_num for 2.12.1 AS_IDs work.

  *****************************************************************************/

  PROCEDURE pr_purge_closed_periods(p_acctId          IN INTEGER := 0
                                   ,p_eventLogTiming  IN INTEGER := 0
                                   ,p_success        OUT INTEGER
                                   ,p_errReason      OUT VARCHAR2
                                   )

  IS
    v_rows_processed INTEGER;
    v_success        INTEGER := 0; -- defaulted to failure
    v_timeDiff       INTEGER := 0;
    v_startTime      DATE;
    v_endTime        DATE;
  BEGIN
    IF p_eventLogTiming = 1
    THEN
      v_startTime := sysdate;
    END IF;

    delete from br_periods bp
          where bp.per_id in(
                    select p1.per_id
                      from br_periods p1
                     where p1.acct_id = p_acctid
                       and p1.period in(
                               select p2.period
                                 from br_periods p2
                                where p2.acct_id = p1.acct_id
                                  and p2.state in(1, 2)
                                  and p2.per_id not in(
                                          select distinct a.record_id
                                                     from br_audit a
                                                    where a.acct_id = p2.acct_id
                                                      and a.sequence_num > g_sequence_num
                                                      and a.type in(10, 11, 12)))
                       and p1.period not in(
                               select distinct d.period
                                          from br_data d
                                         where d.acct_id = p1.acct_id
                                           and d.state <> 6
                                           and d.period in(
                                                   select p3.period
                                                     from br_periods p3
                                                    where p3.acct_id = d.acct_id
                                                      and p3.state in(1, 2)
                                                      and p3.per_id not in(
                                                              select distinct a2.record_id
                                                                         from br_audit a2
                                                                        where a2.acct_id = p3.acct_id
                                                                          and a2.sequence_num > g_sequence_num
                                                                          and a2.type in (10, 11, 12)))));

    v_rows_processed := sql%rowcount;

    commit;

    IF p_eventLogTiming = 1
    THEN
      v_endTime := sysdate;
      v_timeDiff := (v_endTime - v_startTime) * 86400;  -- time given in seconds

      Pkg_Bs_Log_Event.pr_log_timing(p_instance_id => 0
                                    ,p_program_id => 11
                                    ,p_message => 'Closed periods purged: '||to_char(v_rows_processed)||' rows deleted.'
                                    ,p_extra_text => 'Duration: '||to_char(v_timeDiff)||' seconds'
                                    ,p_category_id => 1
                                    ,p_success => v_success);

    END IF;
    v_success := 1;
    p_success := v_success;

  EXCEPTION
  WHEN OTHERS THEN
    p_errReason := 'pr_purge_closed_periods';
    Pkg_Bs_Log_Event.pr_log_error (p_instance_id => 0
                                  ,p_severity_id => 0
                                  ,p_message => 'Error calling pkg_br_purge.pr_purge_closed_periods'
                                  ,p_extra_text => 'Server Error '||to_char(SQLCODE)||' '||SQLERRM
                                  ,p_category_id => 1
                                  ,p_success => v_success
                                  );
    p_success := 0;                  -- calling program needs to know exception raised
  END pr_purge_closed_periods;
      /* ****************************************************************************
   Name:    pr_purge_period_audits
   Date:    31-Mar-2006
   Author:  S.Mace
   Purpose: This procedure is part of the text purge routine and deletes the
            br_audit records from periods no longer in use that associated with an account

            The activity may optionally be timed and the result put into the bs_event_log table.

   Change History

   --------------
   Date     Author              Description of change
   ----     ------              ---------------------
   20-08-07 S.Mace              Replaced p_maxAuditId with use of g_sequence_num for 2.12.1 AS_IDs work.

  *****************************************************************************/

  PROCEDURE pr_purge_period_audits (p_acctId    IN INTEGER := 0
                                   ,p_eventLogTiming  IN INTEGER := 0
                                   ,p_success        OUT INTEGER
                                   ,p_errReason      OUT VARCHAR2
                                   )
  IS
    v_rows_processed INTEGER;
    v_success        INTEGER := 0; -- defaulted to failure
    v_timeDiff       INTEGER := 0;
    v_startTime      DATE;
    v_endTime        DATE;
  BEGIN
    IF p_eventLogTiming = 1
    THEN
      v_startTime := sysdate;
    END IF;

    delete from br_audit bra
          where bra.acct_id = p_acctid
            and bra.sequence_num < g_sequence_num
            and bra.record_id not in(select bp.per_id
                                       from br_periods bp
                                      where bp.acct_id = bra.acct_id)
            and bra.type in(10, 11);

    v_rows_processed := sql%rowcount;

    commit;

    IF p_eventLogTiming = 1
    THEN
      v_endTime := sysdate;
      v_timeDiff := (v_endTime - v_startTime) * 86400;  -- time given in seconds

      Pkg_Bs_Log_Event.pr_log_timing(p_instance_id => 0
                                    ,p_program_id => 11
                                    ,p_message => 'Periods audits purged: '||to_char(v_rows_processed)||' rows deleted.'
                                    ,p_extra_text => 'Duration: '||to_char(v_timeDiff)||' seconds'
                                    ,p_category_id => 1
                                    ,p_success => v_success);

    END IF;
    v_success := 1;
    p_success := v_success;

  EXCEPTION
  WHEN OTHERS THEN
    p_errReason := 'pr_purge_period_audits';
    Pkg_Bs_Log_Event.pr_log_error (p_instance_id => 0
                                  ,p_severity_id => 0
                                  ,p_message => 'Error calling pkg_br_purge.pr_purge_period_audits'
                                  ,p_extra_text => 'Server Error '||to_char(SQLCODE)||' '||SQLERRM
                                  ,p_category_id => 1
                                  ,p_success => v_success
                                  );
    p_success := 0;                  -- calling program needs to know exception raised
  END pr_purge_period_audits;

   /* ****************************************************************************
   Name:    pr_purge_acc_load_audits
   Date:    31-Mar-2006
   Author:  S.Mace
   Purpose: This procedure is part of the text purge routine and deletes the audit records associated with account load
            property records (br_aclprps) being purged by br_purge_acc_loads.

            The activity may optionally be timed and the result put into the bs_event_log table.


   Change History
   --------------
   Date     Author              Description of change
   ----     ------              ---------------------
   17-5-06  S.Mace  Changed delete statement.
                    Used inner joins instead and removed extraneous distinct subquery.
  *****************************************************************************/


  PROCEDURE pr_purge_acc_load_audits (p_acctId    IN INTEGER := 0
                                     ,p_eventLogTiming  IN INTEGER := 0
                                     ,p_success        OUT INTEGER
                                     ,p_errReason      OUT VARCHAR2
                                      )
  IS

    v_rows_processed INTEGER;
    v_success        INTEGER := 0; -- defaulted to failure
    v_timeDiff       INTEGER := 0;
    v_startTime      DATE;
    v_endTime        DATE;
  BEGIN
    IF p_eventLogTiming = 1
    THEN
      v_startTime := sysdate;
    END IF;

    delete from br_audit bra
          where bra.acct_id = p_acctid
            and bra.type = 16
            and not exists(
                      select 1
                        from br_aclprps acl
                             inner join br_data dat
                             on acl.acct_id = dat.acct_id
                           and acl.load_id = dat.load_id
                       where acl.load_id = bra.whichone
                             and acl.acct_id = bra.acct_id);

    v_rows_processed := sql%rowcount;

    commit;

    IF p_eventLogTiming = 1
    THEN
      v_endTime := sysdate;
      v_timeDiff := (v_endTime - v_startTime) * 86400;  -- time given in seconds

      Pkg_Bs_Log_Event.pr_log_timing(p_instance_id => 0
                                    ,p_program_id => 11
                                    ,p_message => 'Account load audits purged: '||to_char(v_rows_processed)||' rows deleted.'
                                    ,p_extra_text => 'Duration: '||to_char(v_timeDiff)||' seconds'
                                    ,p_category_id => 1
                                    ,p_success => v_success);
    END IF;
    v_success := 1;
    p_success := v_success;

  EXCEPTION
  WHEN OTHERS THEN
    p_errReason := 'pr_purge_acc_load_audits';
    Pkg_Bs_Log_Event.pr_log_error (p_instance_id => 0
                                  ,p_severity_id => 0
                                  ,p_message => 'Error calling pkg_pr_purge.pr_purge_acc_load_audits'
                                  ,p_extra_text => 'Server Error '||to_char(SQLCODE)||' '||SQLERRM
                                  ,p_category_id => 1
                                  ,p_success => v_success
                                  );
    p_success := 0;                  -- calling program needs to know exception raised
  END pr_purge_acc_load_audits;

  /* ****************************************************************************
   Name:    pr_purge_acc_loads
   Date:    31-Mar-2006
   Author:  S.Mace
   Purpose: This procedure is part of the text purge routine and deletes the account load property

            records (br_aclprps) associated with the  accounts being purged.

            The activity may optionally be timed and the result put into the bs_event_log table.

   Change History
   --------------
   Date     Author              Description of change
   ----     ------              ---------------------
   17-5-06  S.Mace  Changed delete statement.
                    Used inner joins instead and removed extraneous distinct subquery.
  *****************************************************************************/
  PROCEDURE pr_purge_acc_loads     (p_acctId    IN INTEGER := 0
                                   ,p_eventLogTiming  IN INTEGER := 0
                                   ,p_success        OUT INTEGER
                                   ,p_errReason      OUT VARCHAR2
                                   )
  IS
    v_rows_processed INTEGER;
    v_success        INTEGER := 0; -- defaulted to failure
    v_timeDiff       INTEGER := 0;
    v_startTime      DATE;
    v_endTime        DATE;
  BEGIN
    IF p_eventLogTiming = 1
    THEN
      v_startTime := sysdate;

    END IF;

    delete from br_aclprps acl1
          where acl1.acct_id = p_acctid
            and not exists(
                     select 1
                       from br_data brd
                      where brd.acct_id = acl1.acct_id
                            and brd.load_id = acl1.load_id);

    v_rows_processed := sql%rowcount;

    commit;

    IF p_eventLogTiming = 1
    THEN
      v_endTime := sysdate;
      v_timeDiff := (v_endTime - v_startTime) * 86400;  -- time given in seconds

      Pkg_Bs_Log_Event.pr_log_timing(p_instance_id => 0
                                    ,p_program_id => 11
                                    ,p_message => 'Account load purged: '||to_char(v_rows_processed)||' rows deleted.'
                                    ,p_extra_text => 'Duration: '||to_char(v_timeDiff)||' seconds'
                                    ,p_category_id => 1
                                    ,p_success => v_success);
    END IF;

    v_success := 1;
    p_success := v_success;

  EXCEPTION

  WHEN OTHERS THEN
    p_errReason := 'pr_purge_acc_loads';
    Pkg_Bs_Log_Event.pr_log_error (p_instance_id => 0
                                  ,p_severity_id => 0
                                  ,p_message => 'Error calling pkg_br_purge.pr_purge_acc_loads'
                                  ,p_extra_text => 'Server Error '||to_char(SQLCODE)||' '||SQLERRM
                                  ,p_category_id => 1
                                  ,p_success => v_success
                                  );
    p_success := 0;                  -- calling program needs to know exception raised
  END pr_purge_acc_loads;

    /* ****************************************************************************

   Name:    pr_purge_subacc_bal_audits
   Date:    31-Mar-2006
   Author:  S.Mace
   Purpose: This procedure is part of the text purge routine and deletes the
            br_audits records for the subaccount balances associated with the purged account.

            The activity may optionally be timed and the result put into the bs_event_log table.

   Change History
   --------------
   Date     Author              Description of change
   ----     ------              ---------------------
   20-08-07 S.Mace              Replaced p_maxAuditId with use of g_sequence_num for 2.12.1 AS_IDs work.

  *****************************************************************************/


  PROCEDURE pr_purge_subacc_bal_audits(p_acctId    IN INTEGER := 0
                                      ,p_eventLogTiming  IN INTEGER := 0
                                      ,p_success        OUT INTEGER
                                      ,p_errReason      OUT VARCHAR2
                                      )
  IS
    v_rows_processed INTEGER;
    v_success        INTEGER := 0; -- defaulted to failure
    v_timeDiff       INTEGER := 0;

    v_startTime      DATE;
    v_endTime        DATE;
  BEGIN
    IF p_eventLogTiming = 1
    THEN
      v_startTime := sysdate;
    END IF;

    delete from br_audit
          where acct_id = p_acctid
            and sequence_num < g_sequence_num
            and type = 5;

    v_rows_processed := sql%rowcount;

    commit;

    IF p_eventLogTiming = 1
    THEN
      v_endTime := sysdate;
      v_timeDiff := (v_endTime - v_startTime) * 86400;  -- time given in seconds


      Pkg_Bs_Log_Event.pr_log_timing(p_instance_id => 0
                                    ,p_program_id => 11
                                    ,p_message => 'SubAccount balance audits purged: '||to_char(v_rows_processed)||' rows deleted.'
                                    ,p_extra_text => 'Duration: '||to_char(v_timeDiff)||' seconds'
                                    ,p_category_id => 1
                                    ,p_success => v_success);
    END IF;

    v_success := 1;
    p_success := v_success;


  EXCEPTION

  WHEN OTHERS THEN
    p_errReason := 'pr_purge_subacc_bal_audits';
    Pkg_Bs_Log_Event.pr_log_error (p_instance_id => 0
                                  ,p_severity_id => 0
                                  ,p_message => 'Error calling pkg_br_purge.pr_purge_subacc_bal_audits'
                                  ,p_extra_text => 'Server Error '||to_char(SQLCODE)||' '||SQLERRM
                                  ,p_category_id => 1
                                  ,p_success => v_success
                                  );
    p_success := 0;                  -- calling program needs to know exception raised
  END pr_purge_subacc_bal_audits;

  /* ****************************************************************************

   Name:    pr_purge_subacc_create_audits
   Date:    31-Mar-2006
   Author:  S.Mace
   Purpose: This procedure is part of the text purge routine and deletes the
            br_audits records associated with subaccount creation for the purged account

            The activity may optionally be timed and the result put into the bs_event_log table.

   Change History
   --------------
   Date     Author              Description of change
   ----     ------              ---------------------
   20-08-07 S.Mace              Replaced p_maxAuditId with use of g_sequence_num for 2.12.1 AS_IDs work.

  *****************************************************************************/

  PROCEDURE pr_purge_subacc_create_audits  (p_acctId    IN INTEGER := 0
                                           ,p_eventLogTiming  IN INTEGER := 0
                                           ,p_success        OUT INTEGER
                                           ,p_errReason      OUT VARCHAR2
                                           )
  IS
    v_rows_processed INTEGER;
    v_success        INTEGER := 0; -- defaulted to failure
    v_timeDiff       INTEGER := 0;
    v_startTime      DATE;

    v_endTime        DATE;
  BEGIN
    IF p_eventLogTiming = 1
    THEN
      v_startTime := sysdate;
    END IF;

    delete from br_audit
          where acct_id = p_acctid
            and sequence_num < g_sequence_num
            and type = 17;

    v_rows_processed := sql%rowcount;

    commit;

    IF p_eventLogTiming = 1
    THEN
      v_endTime := sysdate;
      v_timeDiff := (v_endTime - v_startTime) * 86400;  -- time given in seconds


      Pkg_Bs_Log_Event.pr_log_timing(p_instance_id => 0
                                    ,p_program_id => 11
                                    ,p_message => 'SubAccount create audits purged: '||to_char(v_rows_processed)||' rows deleted.'
                                    ,p_extra_text => 'Duration: '||to_char(v_timeDiff)||' seconds'
                                    ,p_category_id => 1
                                    ,p_success => v_success);
    END IF;

    v_success := 1;
    p_success := v_success;


  exception
      when others then
        p_errReason := 'pr_purge_subacc_create_audits';

        Pkg_Bs_Log_Event.pr_log_error (p_instance_id => 0
                                      ,p_severity_id => 0
                                      ,p_message => 'Error calling pkg_br_purge.pr_purge_subacc_create_audits'
                                      ,p_extra_text => 'Server Error '||to_char(SQLCODE)||' '||SQLERRM
                                      ,p_category_id => 1
                                      ,p_success => v_success
                                      );
        p_success := 0;                  -- calling program needs to know exception raised

  END pr_purge_subacc_create_audits;


  /****************************************************************************
   Name:    pr_purge_data_extra_records
   Date:    9-May-2007
   Author:  R.MacKie
   Purpose: This procedure is part of the text purge routine and deletes the br_data_extra
            records associated with the br_data rows held in the specified temporary
      table. The deletion is managed by deleting a set number of records at a
      time in a loop - this is to avoid the job failing for a high number of
      deletions when extents may otherwise be blown.


            The activity may optionally be timed and the result put into the bs_event_log table.

   Change History
   --------------
   Date     Author              Description of change
   ----     ------              ---------------------
  *****************************************************************************/

  PROCEDURE pr_purge_data_extra_records(p_tempTableName     IN VARCHAR2
                                       ,p_acctId            IN INTEGER := 0
                                       ,p_eventLogTiming    IN INTEGER := 0
                                       ,p_purgeBlockSize    IN INTEGER := 0
                                       ,p_timestamp         IN VARCHAR
                                       ,p_version           IN VARCHAR
                                       ,p_deleteReturnsRows IN INTEGER := 0
                                       ,p_purgeFilesDir     IN VARCHAR
                                       ,p_success           OUT INTEGER
                                       ,p_errReason         OUT VARCHAR2
                                       )
  IS
  v_sql_stmt            VARCHAR2(2000);
  v_timeDiff            INTEGER := 0;
  v_success             INTEGER := 0; -- defaulted to failure
  v_output              INTEGER := 0;
  v_begRecordRange      INTEGER := 0;
  v_endRecordRange      INTEGER := 0;
  v_cursor_name         INTEGER;
  v_rows_processed      INTEGER;
  v_tot_rows_processed  INTEGER := 0;
  v_startTime           DATE;
  v_endTime             DATE;
  file_id2              UTL_FILE.FILE_TYPE;
  l_str                 VARCHAR2(32000);
  l_acct_name           VARCHAR2(255);
  v_file_name     VARCHAR2(40) := p_timestamp||'_'||to_char(p_acctid)||'_'||'br_data_extra.txt';

  TYPE v_xdata_recs1 IS TABLE OF BR_DATA_EXTRA.ACCT_ID%TYPE;
  TYPE v_xdata_recs2 IS TABLE OF BR_DATA_EXTRA.RECORD_ID%TYPE;
  TYPE v_xdata_recs3 IS TABLE OF BR_DATA_EXTRA.STR_001%TYPE;
  TYPE v_xdata_recs4 IS TABLE OF BR_DATA_EXTRA.STR_002%TYPE;
  TYPE v_xdata_recs5 IS TABLE OF BR_DATA_EXTRA.STR_003%TYPE;
  TYPE v_xdata_recs6 IS TABLE OF BR_DATA_EXTRA.STR_004%TYPE;
  TYPE v_xdata_recs7 IS TABLE OF BR_DATA_EXTRA.STR_005%TYPE;
  TYPE v_xdata_recs8 IS TABLE OF BR_DATA_EXTRA.STR_006%TYPE;
  TYPE v_xdata_recs9 IS TABLE OF BR_DATA_EXTRA.STR_007%TYPE;
  TYPE v_xdata_recs10 IS TABLE OF BR_DATA_EXTRA.STR_008%TYPE;
  TYPE v_xdata_recs11 IS TABLE OF BR_DATA_EXTRA.STR_009%TYPE;
  TYPE v_xdata_recs12 IS TABLE OF BR_DATA_EXTRA.STR_010%TYPE;
  TYPE v_xdata_recs13 IS TABLE OF BR_DATA_EXTRA.STR_011%TYPE;
  TYPE v_xdata_recs14 IS TABLE OF BR_DATA_EXTRA.STR_012%TYPE;
  TYPE v_xdata_recs15 IS TABLE OF BR_DATA_EXTRA.STR_013%TYPE;
  TYPE v_xdata_recs16 IS TABLE OF BR_DATA_EXTRA.STR_014%TYPE;
  TYPE v_xdata_recs17 IS TABLE OF BR_DATA_EXTRA.STR_015%TYPE;
  TYPE v_xdata_recs18 IS TABLE OF BR_DATA_EXTRA.STR_016%TYPE;
  TYPE v_xdata_recs19 IS TABLE OF BR_DATA_EXTRA.STR_017%TYPE;
  TYPE v_xdata_recs20 IS TABLE OF BR_DATA_EXTRA.STR_018%TYPE;
  TYPE v_xdata_recs21 IS TABLE OF BR_DATA_EXTRA.STR_019%TYPE;
  TYPE v_xdata_recs22 IS TABLE OF BR_DATA_EXTRA.STR_020%TYPE;
  TYPE v_xdata_recs23 IS TABLE OF BR_DATA_EXTRA.STR_021%TYPE;
  TYPE v_xdata_recs24 IS TABLE OF BR_DATA_EXTRA.STR_022%TYPE;
  TYPE v_xdata_recs25 IS TABLE OF BR_DATA_EXTRA.STR_023%TYPE;
  TYPE v_xdata_recs26 IS TABLE OF BR_DATA_EXTRA.STR_024%TYPE;
  TYPE v_xdata_recs27 IS TABLE OF BR_DATA_EXTRA.STR_025%TYPE;
  TYPE v_xdata_recs28 IS TABLE OF BR_DATA_EXTRA.STR_026%TYPE;
  TYPE v_xdata_recs29 IS TABLE OF BR_DATA_EXTRA.STR_027%TYPE;
  TYPE v_xdata_recs30 IS TABLE OF BR_DATA_EXTRA.STR_028%TYPE;
  TYPE v_xdata_recs31 IS TABLE OF BR_DATA_EXTRA.STR_029%TYPE;
  TYPE v_xdata_recs32 IS TABLE OF BR_DATA_EXTRA.STR_030%TYPE;
  TYPE v_xdata_recs33 IS TABLE OF BR_DATA_EXTRA.STR_031%TYPE;
  TYPE v_xdata_recs34 IS TABLE OF BR_DATA_EXTRA.STR_032%TYPE;
  TYPE v_xdata_recs35 IS TABLE OF BR_DATA_EXTRA.STR_033%TYPE;
  TYPE v_xdata_recs36 IS TABLE OF BR_DATA_EXTRA.STR_034%TYPE;
  TYPE v_xdata_recs37 IS TABLE OF BR_DATA_EXTRA.STR_035%TYPE;
  TYPE v_xdata_recs38 IS TABLE OF BR_DATA_EXTRA.STR_036%TYPE;
  TYPE v_xdata_recs39 IS TABLE OF BR_DATA_EXTRA.STR_037%TYPE;
  TYPE v_xdata_recs40 IS TABLE OF BR_DATA_EXTRA.STR_038%TYPE;
  TYPE v_xdata_recs41 IS TABLE OF BR_DATA_EXTRA.STR_039%TYPE;
  TYPE v_xdata_recs42 IS TABLE OF BR_DATA_EXTRA.STR_040%TYPE;
  TYPE v_xdata_recs43 IS TABLE OF BR_DATA_EXTRA.STR_041%TYPE;
  TYPE v_xdata_recs44 IS TABLE OF BR_DATA_EXTRA.STR_042%TYPE;
  TYPE v_xdata_recs45 IS TABLE OF BR_DATA_EXTRA.STR_043%TYPE;
  TYPE v_xdata_recs46 IS TABLE OF BR_DATA_EXTRA.STR_044%TYPE;
  TYPE v_xdata_recs47 IS TABLE OF BR_DATA_EXTRA.STR_045%TYPE;
  TYPE v_xdata_recs48 IS TABLE OF BR_DATA_EXTRA.STR_046%TYPE;
  TYPE v_xdata_recs49 IS TABLE OF BR_DATA_EXTRA.STR_047%TYPE;
  TYPE v_xdata_recs50 IS TABLE OF BR_DATA_EXTRA.STR_048%TYPE;
  TYPE v_xdata_recs51 IS TABLE OF BR_DATA_EXTRA.STR_049%TYPE;
  TYPE v_xdata_recs52 IS TABLE OF BR_DATA_EXTRA.STR_050%TYPE;
  TYPE v_xdata_recs53 IS TABLE OF BR_DATA_EXTRA.STR_051%TYPE;
  TYPE v_xdata_recs54 IS TABLE OF BR_DATA_EXTRA.STR_052%TYPE;
  TYPE v_xdata_recs55 IS TABLE OF BR_DATA_EXTRA.STR_053%TYPE;
  TYPE v_xdata_recs56 IS TABLE OF BR_DATA_EXTRA.STR_054%TYPE;
  TYPE v_xdata_recs57 IS TABLE OF BR_DATA_EXTRA.STR_055%TYPE;
  TYPE v_xdata_recs58 IS TABLE OF BR_DATA_EXTRA.STR_056%TYPE;
  TYPE v_xdata_recs59 IS TABLE OF BR_DATA_EXTRA.STR_057%TYPE;
  TYPE v_xdata_recs60 IS TABLE OF BR_DATA_EXTRA.STR_058%TYPE;
  TYPE v_xdata_recs61 IS TABLE OF BR_DATA_EXTRA.STR_059%TYPE;
  TYPE v_xdata_recs62 IS TABLE OF BR_DATA_EXTRA.STR_060%TYPE;
  TYPE v_xdata_recs63 IS TABLE OF BR_DATA_EXTRA.STR_061%TYPE;
  TYPE v_xdata_recs64 IS TABLE OF BR_DATA_EXTRA.STR_062%TYPE;
  TYPE v_xdata_recs65 IS TABLE OF BR_DATA_EXTRA.STR_063%TYPE;
  TYPE v_xdata_recs66 IS TABLE OF BR_DATA_EXTRA.STR_064%TYPE;
  TYPE v_xdata_recs67 IS TABLE OF BR_DATA_EXTRA.STR_065%TYPE;
  TYPE v_xdata_recs68 IS TABLE OF BR_DATA_EXTRA.STR_066%TYPE;
  TYPE v_xdata_recs69 IS TABLE OF BR_DATA_EXTRA.STR_067%TYPE;
  TYPE v_xdata_recs70 IS TABLE OF BR_DATA_EXTRA.STR_068%TYPE;
  TYPE v_xdata_recs71 IS TABLE OF BR_DATA_EXTRA.STR_069%TYPE;
  TYPE v_xdata_recs72 IS TABLE OF BR_DATA_EXTRA.STR_070%TYPE;
  TYPE v_xdata_recs73 IS TABLE OF BR_DATA_EXTRA.STR_071%TYPE;
  TYPE v_xdata_recs74 IS TABLE OF BR_DATA_EXTRA.STR_072%TYPE;
  TYPE v_xdata_recs75 IS TABLE OF BR_DATA_EXTRA.STR_073%TYPE;
  TYPE v_xdata_recs76 IS TABLE OF BR_DATA_EXTRA.STR_074%TYPE;
  TYPE v_xdata_recs77 IS TABLE OF BR_DATA_EXTRA.STR_075%TYPE;
  TYPE v_xdata_recs78 IS TABLE OF BR_DATA_EXTRA.STR_076%TYPE;
  TYPE v_xdata_recs79 IS TABLE OF BR_DATA_EXTRA.DATE_001%TYPE;
  TYPE v_xdata_recs80 IS TABLE OF BR_DATA_EXTRA.DATE_002%TYPE;
  TYPE v_xdata_recs81 IS TABLE OF BR_DATA_EXTRA.DATE_003%TYPE;
  TYPE v_xdata_recs82 IS TABLE OF BR_DATA_EXTRA.DATE_004%TYPE;
  TYPE v_xdata_recs83 IS TABLE OF BR_DATA_EXTRA.DATE_005%TYPE;
  TYPE v_xdata_recs84 IS TABLE OF BR_DATA_EXTRA.DATE_006%TYPE;
  TYPE v_xdata_recs85 IS TABLE OF BR_DATA_EXTRA.DATE_007%TYPE;
  TYPE v_xdata_recs86 IS TABLE OF BR_DATA_EXTRA.DATE_008%TYPE;
  TYPE v_xdata_recs87 IS TABLE OF BR_DATA_EXTRA.DATE_009%TYPE;
  TYPE v_xdata_recs88 IS TABLE OF BR_DATA_EXTRA.DATE_010%TYPE;
  TYPE v_xdata_recs89 IS TABLE OF BR_DATA_EXTRA.DATE_011%TYPE;
  TYPE v_xdata_recs90 IS TABLE OF BR_DATA_EXTRA.DATE_012%TYPE;
  TYPE v_xdata_recs91 IS TABLE OF BR_DATA_EXTRA.DATE_013%TYPE;
  TYPE v_xdata_recs92 IS TABLE OF BR_DATA_EXTRA.DATE_014%TYPE;
  TYPE v_xdata_recs93 IS TABLE OF BR_DATA_EXTRA.DATE_015%TYPE;
  TYPE v_xdata_recs94 IS TABLE OF BR_DATA_EXTRA.DATE_016%TYPE;
  TYPE v_xdata_recs95 IS TABLE OF BR_DATA_EXTRA.DATE_017%TYPE;
  TYPE v_xdata_recs96 IS TABLE OF BR_DATA_EXTRA.NUM_001%TYPE;
  TYPE v_xdata_recs97 IS TABLE OF BR_DATA_EXTRA.NUM_002%TYPE;
  TYPE v_xdata_recs98 IS TABLE OF BR_DATA_EXTRA.NUM_003%TYPE;
  TYPE v_xdata_recs99 IS TABLE OF BR_DATA_EXTRA.NUM_004%TYPE;
  TYPE v_xdata_recs100 IS TABLE OF BR_DATA_EXTRA.NUM_005%TYPE;
  TYPE v_xdata_recs101 IS TABLE OF BR_DATA_EXTRA.NUM_006%TYPE;
  TYPE v_xdata_recs102 IS TABLE OF BR_DATA_EXTRA.NUM_007%TYPE;
  TYPE v_xdata_recs103 IS TABLE OF BR_DATA_EXTRA.NUM_008%TYPE;
  TYPE v_xdata_recs104 IS TABLE OF BR_DATA_EXTRA.NUM_009%TYPE;
  TYPE v_xdata_recs105 IS TABLE OF BR_DATA_EXTRA.NUM_010%TYPE;
  TYPE v_xdata_recs106 IS TABLE OF BR_DATA_EXTRA.NUM_011%TYPE;
  TYPE v_xdata_recs107 IS TABLE OF BR_DATA_EXTRA.NUM_012%TYPE;
  TYPE v_xdata_recs108 IS TABLE OF BR_DATA_EXTRA.NUM_013%TYPE;
  TYPE v_xdata_recs109 IS TABLE OF BR_DATA_EXTRA.NUM_014%TYPE;
  TYPE v_xdata_recs110 IS TABLE OF BR_DATA_EXTRA.NUM_015%TYPE;
  TYPE v_xdata_recs111 IS TABLE OF BR_DATA_EXTRA.NUM_016%TYPE;
  TYPE v_xdata_recs112 IS TABLE OF BR_DATA_EXTRA.NUM_017%TYPE;
  TYPE v_xdata_recs113 IS TABLE OF BR_DATA_EXTRA.NUM_018%TYPE;
  TYPE v_xdata_recs114 IS TABLE OF BR_DATA_EXTRA.NUM_019%TYPE;
  TYPE v_xdata_recs115 IS TABLE OF BR_DATA_EXTRA.NUM_020%TYPE;
  TYPE v_xdata_recs116 IS TABLE OF BR_DATA_EXTRA.NUM_021%TYPE;
  TYPE v_xdata_recs117 IS TABLE OF BR_DATA_EXTRA.NUM_022%TYPE;
  TYPE v_xdata_recs118 IS TABLE OF BR_DATA_EXTRA.NUM_023%TYPE;
  TYPE v_xdata_recs119 IS TABLE OF BR_DATA_EXTRA.INT_001%TYPE;
  TYPE v_xdata_recs120 IS TABLE OF BR_DATA_EXTRA.INT_002%TYPE;
  TYPE v_xdata_recs121 IS TABLE OF BR_DATA_EXTRA.INT_003%TYPE;
  TYPE v_xdata_recs122 IS TABLE OF BR_DATA_EXTRA.INT_004%TYPE;
  TYPE v_xdata_recs123 IS TABLE OF BR_DATA_EXTRA.INT_005%TYPE;
  TYPE v_xdata_recs124 IS TABLE OF BR_DATA_EXTRA.INT_006%TYPE;
  TYPE v_xdata_recs125 IS TABLE OF BR_DATA_EXTRA.INT_007%TYPE;
  TYPE v_xdata_recs126 IS TABLE OF BR_DATA_EXTRA.INT_008%TYPE;
  TYPE v_xdata_recs127 IS TABLE OF BR_DATA_EXTRA.INT_009%TYPE;
  TYPE v_xdata_recs128 IS TABLE OF BR_DATA_EXTRA.INT_010%TYPE;
  TYPE v_xdata_recs129 IS TABLE OF BR_DATA_EXTRA.INT_011%TYPE;
  l_xdata_recs1 v_xdata_recs1;
  l_xdata_recs2 v_xdata_recs2;
  l_xdata_recs3 v_xdata_recs3;
  l_xdata_recs4 v_xdata_recs4;
  l_xdata_recs5 v_xdata_recs5;
  l_xdata_recs6 v_xdata_recs6;
  l_xdata_recs7 v_xdata_recs7;
  l_xdata_recs8 v_xdata_recs8;
  l_xdata_recs9 v_xdata_recs9;
  l_xdata_recs10 v_xdata_recs10;
  l_xdata_recs11 v_xdata_recs11;
  l_xdata_recs12 v_xdata_recs12;
  l_xdata_recs13 v_xdata_recs13;
  l_xdata_recs14 v_xdata_recs14;
  l_xdata_recs15 v_xdata_recs15;
  l_xdata_recs16 v_xdata_recs16;
  l_xdata_recs17 v_xdata_recs17;
  l_xdata_recs18 v_xdata_recs18;
  l_xdata_recs19 v_xdata_recs19;
  l_xdata_recs20 v_xdata_recs20;
  l_xdata_recs21 v_xdata_recs21;
  l_xdata_recs22 v_xdata_recs22;
  l_xdata_recs23 v_xdata_recs23;
  l_xdata_recs24 v_xdata_recs24;
  l_xdata_recs25 v_xdata_recs25;
  l_xdata_recs26 v_xdata_recs26;
  l_xdata_recs27 v_xdata_recs27;
  l_xdata_recs28 v_xdata_recs28;
  l_xdata_recs29 v_xdata_recs29;
  l_xdata_recs30 v_xdata_recs30;
  l_xdata_recs31 v_xdata_recs31;
  l_xdata_recs32 v_xdata_recs32;
  l_xdata_recs33 v_xdata_recs33;
  l_xdata_recs34 v_xdata_recs34;
  l_xdata_recs35 v_xdata_recs35;
  l_xdata_recs36 v_xdata_recs36;
  l_xdata_recs37 v_xdata_recs37;
  l_xdata_recs38 v_xdata_recs38;
  l_xdata_recs39 v_xdata_recs39;
  l_xdata_recs40 v_xdata_recs40;
  l_xdata_recs41 v_xdata_recs41;
  l_xdata_recs42 v_xdata_recs42;
  l_xdata_recs43 v_xdata_recs43;
  l_xdata_recs44 v_xdata_recs44;
  l_xdata_recs45 v_xdata_recs45;
  l_xdata_recs46 v_xdata_recs46;
  l_xdata_recs47 v_xdata_recs47;
  l_xdata_recs48 v_xdata_recs48;
  l_xdata_recs49 v_xdata_recs49;
  l_xdata_recs50 v_xdata_recs50;
  l_xdata_recs51 v_xdata_recs51;
  l_xdata_recs52 v_xdata_recs52;
  l_xdata_recs53 v_xdata_recs53;
  l_xdata_recs54 v_xdata_recs54;
  l_xdata_recs55 v_xdata_recs55;
  l_xdata_recs56 v_xdata_recs56;
  l_xdata_recs57 v_xdata_recs57;
  l_xdata_recs58 v_xdata_recs58;
  l_xdata_recs59 v_xdata_recs59;
  l_xdata_recs60 v_xdata_recs60;
  l_xdata_recs61 v_xdata_recs61;
  l_xdata_recs62 v_xdata_recs62;
  l_xdata_recs63 v_xdata_recs63;
  l_xdata_recs64 v_xdata_recs64;
  l_xdata_recs65 v_xdata_recs65;
  l_xdata_recs66 v_xdata_recs66;
  l_xdata_recs67 v_xdata_recs67;
  l_xdata_recs68 v_xdata_recs68;
  l_xdata_recs69 v_xdata_recs69;
  l_xdata_recs70 v_xdata_recs70;
  l_xdata_recs71 v_xdata_recs71;
  l_xdata_recs72 v_xdata_recs72;
  l_xdata_recs73 v_xdata_recs73;
  l_xdata_recs74 v_xdata_recs74;
  l_xdata_recs75 v_xdata_recs75;
  l_xdata_recs76 v_xdata_recs76;
  l_xdata_recs77 v_xdata_recs77;
  l_xdata_recs78 v_xdata_recs78;
  l_xdata_recs79 v_xdata_recs79;
  l_xdata_recs80 v_xdata_recs80;
  l_xdata_recs81 v_xdata_recs81;
  l_xdata_recs82 v_xdata_recs82;
  l_xdata_recs83 v_xdata_recs83;
  l_xdata_recs84 v_xdata_recs84;
  l_xdata_recs85 v_xdata_recs85;
  l_xdata_recs86 v_xdata_recs86;
  l_xdata_recs87 v_xdata_recs87;
  l_xdata_recs88 v_xdata_recs88;
  l_xdata_recs89 v_xdata_recs89;
  l_xdata_recs90 v_xdata_recs90;
  l_xdata_recs91 v_xdata_recs91;
  l_xdata_recs92 v_xdata_recs92;
  l_xdata_recs93 v_xdata_recs93;
  l_xdata_recs94 v_xdata_recs94;
  l_xdata_recs95 v_xdata_recs95;
  l_xdata_recs96 v_xdata_recs96;
  l_xdata_recs97 v_xdata_recs97;
  l_xdata_recs98 v_xdata_recs98;
  l_xdata_recs99 v_xdata_recs99;
  l_xdata_recs100 v_xdata_recs100;
  l_xdata_recs101 v_xdata_recs101;
  l_xdata_recs102 v_xdata_recs102;
  l_xdata_recs103 v_xdata_recs103;
  l_xdata_recs104 v_xdata_recs104;
  l_xdata_recs105 v_xdata_recs105;
  l_xdata_recs106 v_xdata_recs106;
  l_xdata_recs107 v_xdata_recs107;
  l_xdata_recs108 v_xdata_recs108;
  l_xdata_recs109 v_xdata_recs109;
  l_xdata_recs110 v_xdata_recs110;
  l_xdata_recs111 v_xdata_recs111;
  l_xdata_recs112 v_xdata_recs112;
  l_xdata_recs113 v_xdata_recs113;
  l_xdata_recs114 v_xdata_recs114;
  l_xdata_recs115 v_xdata_recs115;
  l_xdata_recs116 v_xdata_recs116;
  l_xdata_recs117 v_xdata_recs117;
  l_xdata_recs118 v_xdata_recs118;
  l_xdata_recs119 v_xdata_recs119;
  l_xdata_recs120 v_xdata_recs120;
  l_xdata_recs121 v_xdata_recs121;
  l_xdata_recs122 v_xdata_recs122;
  l_xdata_recs123 v_xdata_recs123;
  l_xdata_recs124 v_xdata_recs124;
  l_xdata_recs125 v_xdata_recs125;
  l_xdata_recs126 v_xdata_recs126;
  l_xdata_recs127 v_xdata_recs127;
  l_xdata_recs128 v_xdata_recs128;
  l_xdata_recs129 v_xdata_recs129;

  BEGIN
    IF p_eventLogTiming = 1
    THEN
      v_startTime := sysdate;
    END IF;
    --
    -- prepare to purge data records associated with those loaded in the temporary table
    --
    --
    -- reinitialise variables controlling number of records processed per loop
    --
    v_begRecordRange := g_min_record_id;
    v_endRecordRange := g_min_record_id + p_purgeBlockSize;
    --
    IF p_deleteReturnsRows = 1 THEN
      file_id2 := UTL_FILE.FOPEN(p_PurgeFilesDir,v_file_name,'a',32767);

      select acct_name
      into l_acct_name
      from bs_accts
      where acct_id = p_acctid;

      l_str := p_timestamp||chr(127)||'br_data_extra'||chr(127)||p_version||chr(127)||to_char(p_acctid)||chr(127)||l_acct_name;

      UTL_FILE.PUT_LINE(file_id2, l_str);

      l_str :=  'ACCT_ID'||chr(127)||
                'RECORD_ID'||chr(127)||
                'STR_001'||chr(127)||
                'STR_002'||chr(127)||
                'STR_003'||chr(127)||
                'STR_004'||chr(127)||
                'STR_005'||chr(127)||
                'STR_006'||chr(127)||
                'STR_007'||chr(127)||
                'STR_008'||chr(127)||
                'STR_009'||chr(127)||
                'STR_010'||chr(127)||
                'STR_011'||chr(127)||
                'STR_012'||chr(127)||
                'STR_013'||chr(127)||
                'STR_014'||chr(127)||
                'STR_015'||chr(127)||
                'STR_016'||chr(127)||
                'STR_017'||chr(127)||
                'STR_018'||chr(127)||
                'STR_019'||chr(127)||
                'STR_020'||chr(127)||
                'STR_021'||chr(127)||
                'STR_022'||chr(127)||
                'STR_023'||chr(127)||
                'STR_024'||chr(127)||
                'STR_025'||chr(127)||
                'STR_026'||chr(127)||
                'STR_027'||chr(127)||
                'STR_028'||chr(127)||
                'STR_029'||chr(127)||
                'STR_030'||chr(127)||
                'STR_031'||chr(127)||
                'STR_032'||chr(127)||
                'STR_033'||chr(127)||
                'STR_034'||chr(127)||
                'STR_035'||chr(127)||
                'STR_036'||chr(127)||
                'STR_037'||chr(127)||
                'STR_038'||chr(127)||
                'STR_039'||chr(127)||
                'STR_040'||chr(127)||
                'STR_041'||chr(127)||
                'STR_042'||chr(127)||
                'STR_043'||chr(127)||
                'STR_044'||chr(127)||
                'STR_045'||chr(127)||
                'STR_046'||chr(127)||
                'STR_047'||chr(127)||
                'STR_048'||chr(127)||
                'STR_049'||chr(127)||
                'STR_050'||chr(127)||
                'STR_051'||chr(127)||
                'STR_052'||chr(127)||
                'STR_053'||chr(127)||
                'STR_054'||chr(127)||
                'STR_055'||chr(127)||
                'STR_056'||chr(127)||
                'STR_057'||chr(127)||
                'STR_058'||chr(127)||
                'STR_059'||chr(127)||
                'STR_060'||chr(127)||
                'STR_061'||chr(127)||
                'STR_062'||chr(127)||
                'STR_063'||chr(127)||
                'STR_064'||chr(127)||
                'STR_065'||chr(127)||
                'STR_066'||chr(127)||
                'STR_067'||chr(127)||
                'STR_068'||chr(127)||
                'STR_069'||chr(127)||
                'STR_070'||chr(127)||
                'STR_071'||chr(127)||
                'STR_072'||chr(127)||
                'STR_073'||chr(127)||
                'STR_074'||chr(127)||
                'STR_075'||chr(127)||
                'STR_076'||chr(127)||
                'DATE_001'||chr(127)||
                'DATE_002'||chr(127)||
                'DATE_003'||chr(127)||
                'DATE_004'||chr(127)||
                'DATE_005'||chr(127)||
                'DATE_006'||chr(127)||
                'DATE_007'||chr(127)||
                'DATE_008'||chr(127)||
                'DATE_009'||chr(127)||
                'DATE_010'||chr(127)||
                'DATE_011'||chr(127)||
                'DATE_012'||chr(127)||
                'DATE_013'||chr(127)||
                'DATE_014'||chr(127)||
                'DATE_015'||chr(127)||
                'DATE_016'||chr(127)||
                'DATE_017'||chr(127)||
                'NUM_001'||chr(127)||
                'NUM_002'||chr(127)||
                'NUM_003'||chr(127)||
                'NUM_004'||chr(127)||
                'NUM_005'||chr(127)||
                'NUM_006'||chr(127)||
                'NUM_007'||chr(127)||
                'NUM_008'||chr(127)||
                'NUM_009'||chr(127)||
                'NUM_010'||chr(127)||
                'NUM_011'||chr(127)||
                'NUM_012'||chr(127)||
                'NUM_013'||chr(127)||
                'NUM_014'||chr(127)||
                'NUM_015'||chr(127)||
                'NUM_016'||chr(127)||
                'NUM_017'||chr(127)||
                'NUM_018'||chr(127)||
                'NUM_019'||chr(127)||
                'NUM_020'||chr(127)||
                'NUM_021'||chr(127)||
                'NUM_022'||chr(127)||
                'NUM_023'||chr(127)||
                'INT_001'||chr(127)||
                'INT_002'||chr(127)||
                'INT_003'||chr(127)||
                'INT_004'||chr(127)||
                'INT_005'||chr(127)||
                'INT_006'||chr(127)||
                'INT_007'||chr(127)||
                'INT_008'||chr(127)||
                'INT_009'||chr(127)||
                'INT_010'||chr(127)||
                'INT_011';

      UTL_FILE.PUT_LINE(file_id2, l_str);
    END IF;

    WHILE (v_begRecordRange <= g_max_record_id)
    LOOP
      EXECUTE IMMEDIATE 'DELETE '||
                        'FROM BR_DATA_EXTRA BRDE '||
                        'WHERE BRDE.ACCT_ID = :1 '||
                        'AND   brde.record_id BETWEEN :2 and :3  '||
                        'AND exists (select ''x'' from '||p_tempTableName||
                        '            where acct_id = brde.acct_id '||
                        '          and record_id = brde.record_id) '||
                        '  returning  ACCT_ID,
                                      RECORD_ID,
                                      STR_001,
                                      STR_002,
                                      STR_003,
                                      STR_004,
                                      STR_005,
                                      STR_006,
                                      STR_007,
                                      STR_008,
                                      STR_009,
                                      STR_010,
                                      STR_011,
                                      STR_012,
                                      STR_013,
                                      STR_014,
                                      STR_015,
                                      STR_016,
                                      STR_017,
                                      STR_018,
                                      STR_019,
                                      STR_020,
                                      STR_021,
                                      STR_022,
                                      STR_023,
                                      STR_024,
                                      STR_025,
                                      STR_026,
                                      STR_027,
                                      STR_028,
                                      STR_029,
                                      STR_030,
                                      STR_031,
                                      STR_032,
                                      STR_033,
                                      STR_034,
                                      STR_035,
                                      STR_036,
                                      STR_037,
                                      STR_038,
                                      STR_039,
                                      STR_040,
                                      STR_041,
                                      STR_042,
                                      STR_043,
                                      STR_044,
                                      STR_045,
                                      STR_046,
                                      STR_047,
                                      STR_048,
                                      STR_049,
                                      STR_050,
                                      STR_051,
                                      STR_052,
                                      STR_053,
                                      STR_054,
                                      STR_055,
                                      STR_056,
                                      STR_057,
                                      STR_058,
                                      STR_059,
                                      STR_060,
                                      STR_061,
                                      STR_062,
                                      STR_063,
                                      STR_064,
                                      STR_065,
                                      STR_066,
                                      STR_067,
                                      STR_068,
                                      STR_069,
                                      STR_070,
                                      STR_071,
                                      STR_072,
                                      STR_073,
                                      STR_074,
                                      STR_075,
                                      STR_076,
                                      DATE_001,
                                      DATE_002,
                                      DATE_003,
                                      DATE_004,
                                      DATE_005,
                                      DATE_006,
                                      DATE_007,
                                      DATE_008,
                                      DATE_009,
                                      DATE_010,
                                      DATE_011,
                                      DATE_012,
                                      DATE_013,
                                      DATE_014,
                                      DATE_015,
                                      DATE_016,
                                      DATE_017,
                                      NUM_001,
                                      NUM_002,
                                      NUM_003,
                                      NUM_004,
                                      NUM_005,
                                      NUM_006,
                                      NUM_007,
                                      NUM_008,
                                      NUM_009,
                                      NUM_010,
                                      NUM_011,
                                      NUM_012,
                                      NUM_013,
                                      NUM_014,
                                      NUM_015,
                                      NUM_016,
                                      NUM_017,
                                      NUM_018,
                                      NUM_019,
                                      NUM_020,
                                      NUM_021,
                                      NUM_022,
                                      NUM_023,
                                      INT_001,
                                      INT_002,
                                      INT_003,
                                      INT_004,
                                      INT_005,
                                      INT_006,
                                      INT_007,
                                      INT_008,
                                      INT_009,
                                      INT_010,
                                      INT_011
                        INTO  :4,:5,:6,:7,:8,:9,:10,:11,:12,:13,:14,:15,:16,:17,:18,:19,:20,
                              :21,:22,:23,:24,:25,:26,:27,:28,:29,:30,:31,:32,:33,:34,:35,:36,:37,:38,:39,:40,
                              :41,:42,:43,:44,:45,:46,:47,:48,:49,:50,:51,:52,:53,:54,:55,:56,:57,:58,:59,:60,
                              :61,:62,:63,:64,:65,:66,:67,:68,:69,:70,:71,:72,:73,:74,:75,:76,:77,:78,:79,:80,
                              :81,:82,:83,:84,:85,:86,:87,:88,:89,:90,:91,:92,:93,:94,:95,:96,:97,:98,:99,:100,
                              :101,:102,:103,:104,:105,:106,:107,:108,:109,:110,:111,:112,:113,:114,:115,:116,
                              :117,:118,:119,:120,:121,:122,:123,:124,:125,:126,:127,:128,:129,:130,:131,:132 '
      using p_acctId,v_begRecordRange,v_endRecordRange RETURNING BULK COLLECT INTO
              l_xdata_recs1,
              l_xdata_recs2,
              l_xdata_recs3,
              l_xdata_recs4,
              l_xdata_recs5,
              l_xdata_recs6,
              l_xdata_recs7,
              l_xdata_recs8,
              l_xdata_recs9,
              l_xdata_recs10,
              l_xdata_recs11,
              l_xdata_recs12,
              l_xdata_recs13,
              l_xdata_recs14,
              l_xdata_recs15,
              l_xdata_recs16,
              l_xdata_recs17,
              l_xdata_recs18,
              l_xdata_recs19,
              l_xdata_recs20,
              l_xdata_recs21,
              l_xdata_recs22,
              l_xdata_recs23,
              l_xdata_recs24,
              l_xdata_recs25,
              l_xdata_recs26,
              l_xdata_recs27,
              l_xdata_recs28,
              l_xdata_recs29,
              l_xdata_recs30,
              l_xdata_recs31,
              l_xdata_recs32,
              l_xdata_recs33,
              l_xdata_recs34,
              l_xdata_recs35,
              l_xdata_recs36,
              l_xdata_recs37,
              l_xdata_recs38,
              l_xdata_recs39,
              l_xdata_recs40,
              l_xdata_recs41,
              l_xdata_recs42,
              l_xdata_recs43,
              l_xdata_recs44,
              l_xdata_recs45,
              l_xdata_recs46,
              l_xdata_recs47,
              l_xdata_recs48,
              l_xdata_recs49,
              l_xdata_recs50,
              l_xdata_recs51,
              l_xdata_recs52,
              l_xdata_recs53,
              l_xdata_recs54,
              l_xdata_recs55,
              l_xdata_recs56,
              l_xdata_recs57,
              l_xdata_recs58,
              l_xdata_recs59,
              l_xdata_recs60,
              l_xdata_recs61,
              l_xdata_recs62,
              l_xdata_recs63,
              l_xdata_recs64,
              l_xdata_recs65,
              l_xdata_recs66,
              l_xdata_recs67,
              l_xdata_recs68,
              l_xdata_recs69,
              l_xdata_recs70,
              l_xdata_recs71,
              l_xdata_recs72,
              l_xdata_recs73,
              l_xdata_recs74,
              l_xdata_recs75,
              l_xdata_recs76,
              l_xdata_recs77,
              l_xdata_recs78,
              l_xdata_recs79,
              l_xdata_recs80,
              l_xdata_recs81,
              l_xdata_recs82,
              l_xdata_recs83,
              l_xdata_recs84,
              l_xdata_recs85,
              l_xdata_recs86,
              l_xdata_recs87,
              l_xdata_recs88,
              l_xdata_recs89,
              l_xdata_recs90,
              l_xdata_recs91,
              l_xdata_recs92,
              l_xdata_recs93,
              l_xdata_recs94,
              l_xdata_recs95,
              l_xdata_recs96,
              l_xdata_recs97,
              l_xdata_recs98,
              l_xdata_recs99,
              l_xdata_recs100,
              l_xdata_recs101,
              l_xdata_recs102,
              l_xdata_recs103,
              l_xdata_recs104,
              l_xdata_recs105,
              l_xdata_recs106,
              l_xdata_recs107,
              l_xdata_recs108,
              l_xdata_recs109,
              l_xdata_recs110,
              l_xdata_recs111,
              l_xdata_recs112,
              l_xdata_recs113,
              l_xdata_recs114,
              l_xdata_recs115,
              l_xdata_recs116,
              l_xdata_recs117,
              l_xdata_recs118,
              l_xdata_recs119,
              l_xdata_recs120,
              l_xdata_recs121,
              l_xdata_recs122,
              l_xdata_recs123,
              l_xdata_recs124,
              l_xdata_recs125,
              l_xdata_recs126,
              l_xdata_recs127,
              l_xdata_recs128,
              l_xdata_recs129;

      IF l_xdata_recs1.count > 0 THEN
        v_tot_rows_processed := v_tot_rows_processed + l_xdata_recs1.count;

        IF p_deleteReturnsRows = 1 THEN
          FOR indx IN l_xdata_recs1.first .. l_xdata_recs1.last
          LOOP
            l_str :=  to_char(l_xdata_recs1(indx))||chr(127)||
                      to_char(l_xdata_recs2(indx))||chr(127)||
                      l_xdata_recs3(indx)||chr(127)||
                      l_xdata_recs4(indx)||chr(127)||
                      l_xdata_recs5(indx)||chr(127)||
                      l_xdata_recs6(indx)||chr(127)||
                      l_xdata_recs7(indx)||chr(127)||
                      l_xdata_recs8(indx)||chr(127)||
                      l_xdata_recs9(indx)||chr(127)||
                      l_xdata_recs10(indx)||chr(127)||
                      l_xdata_recs11(indx)||chr(127)||
                      l_xdata_recs12(indx)||chr(127)||
                      l_xdata_recs13(indx)||chr(127)||
                      l_xdata_recs14(indx)||chr(127)||
                      l_xdata_recs15(indx)||chr(127)||
                      l_xdata_recs16(indx)||chr(127)||
                      l_xdata_recs17(indx)||chr(127)||
                      l_xdata_recs18(indx)||chr(127)||
                      l_xdata_recs19(indx)||chr(127)||
                      l_xdata_recs20(indx)||chr(127)||
                      l_xdata_recs21(indx)||chr(127)||
                      l_xdata_recs22(indx)||chr(127)||
                      l_xdata_recs23(indx)||chr(127)||
                      l_xdata_recs24(indx)||chr(127)||
                      l_xdata_recs25(indx)||chr(127)||
                      l_xdata_recs26(indx)||chr(127)||
                      l_xdata_recs27(indx)||chr(127)||
                      l_xdata_recs28(indx)||chr(127)||
                      l_xdata_recs29(indx)||chr(127)||
                      l_xdata_recs30(indx)||chr(127)||
                      l_xdata_recs31(indx)||chr(127)||
                      l_xdata_recs32(indx)||chr(127)||
                      l_xdata_recs33(indx)||chr(127)||
                      l_xdata_recs34(indx)||chr(127)||
                      l_xdata_recs35(indx)||chr(127)||
                      l_xdata_recs36(indx)||chr(127)||
                      l_xdata_recs37(indx)||chr(127)||
                      l_xdata_recs38(indx)||chr(127)||
                      l_xdata_recs39(indx)||chr(127)||
                      l_xdata_recs40(indx)||chr(127)||
                      l_xdata_recs41(indx)||chr(127)||
                      l_xdata_recs42(indx)||chr(127)||
                      l_xdata_recs43(indx)||chr(127)||
                      l_xdata_recs44(indx)||chr(127)||
                      l_xdata_recs45(indx)||chr(127)||
                      l_xdata_recs46(indx)||chr(127)||
                      l_xdata_recs47(indx)||chr(127)||
                      l_xdata_recs48(indx)||chr(127)||
                      l_xdata_recs49(indx)||chr(127)||
                      l_xdata_recs50(indx)||chr(127)||
                      l_xdata_recs51(indx)||chr(127)||
                      l_xdata_recs52(indx)||chr(127)||
                      l_xdata_recs53(indx)||chr(127)||
                      l_xdata_recs54(indx)||chr(127)||
                      l_xdata_recs55(indx)||chr(127)||
                      l_xdata_recs56(indx)||chr(127)||
                      l_xdata_recs57(indx)||chr(127)||
                      l_xdata_recs58(indx)||chr(127)||
                      l_xdata_recs59(indx)||chr(127)||
                      l_xdata_recs60(indx)||chr(127)||
                      l_xdata_recs61(indx)||chr(127)||
                      l_xdata_recs62(indx)||chr(127)||
                      l_xdata_recs63(indx)||chr(127)||
                      l_xdata_recs64(indx)||chr(127)||
                      l_xdata_recs65(indx)||chr(127)||
                      l_xdata_recs66(indx)||chr(127)||
                      l_xdata_recs67(indx)||chr(127)||
                      l_xdata_recs68(indx)||chr(127)||
                      l_xdata_recs69(indx)||chr(127)||
                      l_xdata_recs70(indx)||chr(127)||
                      l_xdata_recs71(indx)||chr(127)||
                      l_xdata_recs72(indx)||chr(127)||
                      l_xdata_recs73(indx)||chr(127)||
                      l_xdata_recs74(indx)||chr(127)||
                      l_xdata_recs75(indx)||chr(127)||
                      l_xdata_recs76(indx)||chr(127)||
                      l_xdata_recs77(indx)||chr(127)||
                      l_xdata_recs78(indx)||chr(127)||
                      to_char(l_xdata_recs79(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                      to_char(l_xdata_recs80(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                      to_char(l_xdata_recs81(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                      to_char(l_xdata_recs82(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                      to_char(l_xdata_recs83(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                      to_char(l_xdata_recs84(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                      to_char(l_xdata_recs85(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                      to_char(l_xdata_recs86(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                      to_char(l_xdata_recs87(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                      to_char(l_xdata_recs88(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                      to_char(l_xdata_recs89(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                      to_char(l_xdata_recs90(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                      to_char(l_xdata_recs91(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                      to_char(l_xdata_recs92(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                      to_char(l_xdata_recs93(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                      to_char(l_xdata_recs94(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                      to_char(l_xdata_recs95(indx),'yyyy/mm/dd hh24:mi:ss')||chr(127)||
                      to_char(l_xdata_recs96(indx))||chr(127)||
                      to_char(l_xdata_recs97(indx))||chr(127)||
                      to_char(l_xdata_recs98(indx))||chr(127)||
                      to_char(l_xdata_recs99(indx))||chr(127)||
                      to_char(l_xdata_recs100(indx))||chr(127)||
                      to_char(l_xdata_recs101(indx))||chr(127)||
                      to_char(l_xdata_recs102(indx))||chr(127)||
                      to_char(l_xdata_recs103(indx))||chr(127)||
                      to_char(l_xdata_recs104(indx))||chr(127)||
                      to_char(l_xdata_recs105(indx))||chr(127)||
                      to_char(l_xdata_recs106(indx))||chr(127)||
                      to_char(l_xdata_recs107(indx))||chr(127)||
                      to_char(l_xdata_recs108(indx))||chr(127)||
                      to_char(l_xdata_recs109(indx))||chr(127)||
                      to_char(l_xdata_recs110(indx))||chr(127)||
                      to_char(l_xdata_recs111(indx))||chr(127)||
                      to_char(l_xdata_recs112(indx))||chr(127)||
                      to_char(l_xdata_recs113(indx))||chr(127)||
                      to_char(l_xdata_recs114(indx))||chr(127)||
                      to_char(l_xdata_recs115(indx))||chr(127)||
                      to_char(l_xdata_recs116(indx))||chr(127)||
                      to_char(l_xdata_recs117(indx))||chr(127)||
                      to_char(l_xdata_recs118(indx))||chr(127)||
                      to_char(l_xdata_recs119(indx))||chr(127)||
                      to_char(l_xdata_recs120(indx))||chr(127)||
                      to_char(l_xdata_recs121(indx))||chr(127)||
                      to_char(l_xdata_recs122(indx))||chr(127)||
                      to_char(l_xdata_recs123(indx))||chr(127)||
                      to_char(l_xdata_recs124(indx))||chr(127)||
                      to_char(l_xdata_recs125(indx))||chr(127)||
                      to_char(l_xdata_recs126(indx))||chr(127)||
                      to_char(l_xdata_recs127(indx))||chr(127)||
                      to_char(l_xdata_recs128(indx))||chr(127)||
                      to_char(l_xdata_recs129(indx))||chr(127);
            replace_tab_cr_line_feed(l_str);

            UTL_FILE.PUT_LINE(file_id2, l_str);
          END LOOP;

        END IF;

      END IF;

      COMMIT;
      --
      -- increment the records to be processed in the next loop
      --
      v_begRecordRange := v_endRecordRange + 1;
      v_endRecordRange := v_endRecordRange + p_purgeBlockSize;
      --
    END LOOP;

    COMMIT;

    IF p_deleteReturnsRows = 1 THEN

      UTL_FILE.FCLOSE(file_id2);
      file_id2.ID := NULL;

    END IF;

    IF p_eventLogTiming = 1
    THEN
      v_endTime := sysdate;

      v_timeDiff := (v_endTime - v_startTime) * 86400;  -- time given in seconds
      v_rows_processed := v_rows_processed + v_rows_processed;
      Pkg_Bs_Log_Event.pr_log_timing(p_instance_id => 0
                                    ,p_program_id => 11
                                    ,p_message => 'BR data extra records purged '||to_char(v_tot_rows_processed)||' rows deleted.'
                                    ,p_extra_text => 'Duration: '||to_char(v_timeDiff)||' seconds'
                                    ,p_category_id => 1
                                    ,p_success => v_success);
    END IF;

    v_success := 1;
    p_success := v_success;


  EXCEPTION
  WHEN OTHERS THEN

    IF p_deleteReturnsRows = 1 THEN
      UTL_FILE.FCLOSE(file_id2);
      file_id2.ID := NULL;
    END IF;

    p_errReason := 'purge_data_records';
    Pkg_Bs_Log_Event.pr_log_error (p_instance_id => 0
                                  ,p_severity_id => 0
                                  ,p_message => 'Error calling pkg_br_purge.pr_purge_data_extra_records'
                                  ,p_extra_text => 'Server Error '||to_char(SQLCODE)||' '||SQLERRM
                                  ,p_category_id => 1
                                  ,p_success => v_output
                                  );
    p_success := 0;                  -- calling program needs to know exception raised

  END pr_purge_data_extra_records;

  procedure pr_purge_orphan_records(p_success            out integer
                                    ,p_errReason          out varchar2
                                  )
  is
/****************************************************************************
   Name:    pr_purge_orphan_records
   Purpose: This procedure purges the orphan records left over from any previous
            unsuccessful run of txtpurge.
            The orphan records to be deleted are obtained from the
			The data is held temporarily as a driving table for deletions
            handled by other procedures.


  *****************************************************************************/

  v_success        INTEGER := 0; -- defaulted to failure
  v_rows_processed INTEGER :=1;
  v_min_record_id  INTEGER;
  v_max_record_id  INTEGER;
  cursor acct_cursor is select distinct acct_id from tempacc;
  cur_acctid       INTEGER;

BEGIN

	--	If even a single record of brt_purge_orphan_records table has exec_flag = 1,
--	then exit as purger of Orphans is under progress

	SELECT count (1) into v_rows_processed from  brt_purge_orphan_records where exec_flag = 1;
	if (v_rows_processed > 0) then
		p_success := 1 ;
		p_errReason := NULL ;
		return;
	end	if;

-- 	If no orphan records are available then exit
	SELECT count (1) into v_rows_processed from  brt_purge_orphan_records where exec_flag = 0;
	if (v_rows_processed = 0) then
		p_success := 1 ;
		p_errReason := NULL ;
		return;
	end	if;

--  Mark all orphan records under execution
	update brt_purge_orphan_records set exec_flag = 1 where exec_flag = 0;

	INSERT  INTO 	tempacc (acct_id, record_id, orig_id, note_group)
			SELECT        	acct_id, record_id, orig_id, note_group
			FROM  	brt_purge_orphan_records where exec_flag = 1;

    -- Get the minimum and maximum record id, orig_id
    -- br_audit_cycle_assign has no record_id, and br_audit.record_id is not populated for
    -- cycle assignment audit, the orig_id is required for chunking for purging this

	OPEN acct_cursor;
	LOOP
		FETCH acct_cursor INTO cur_acctid;
		EXIT WHEN acct_cursor%NOTFOUND;
		begin
			select  min(record_id), max(record_id), min(orig_id), max(orig_id),acct_id
			into g_min_record_id, g_max_record_id, g_min_orig_id, g_max_orig_id,g_acct_id
			from tempacc where acct_id = cur_acctid group by acct_id;
		exception
		WHEN no_data_found THEN
			g_min_record_id :=0;
			g_max_record_id := 0;
			g_min_orig_id := 0;
			g_max_orig_id := 0;
			g_acct_id := 0;
			v_rows_processed := 0;
		when others then
			raise;
		end;

		delete from br_audit bra
			  where bra.acct_id = g_acct_id
					and bra.record_id between g_min_record_id and g_max_record_id
					and exists
						   (select 'x'
							  from tempacc
							 where acct_id = bra.acct_id
								   and record_id = bra.record_id)
					and (   bra.type = 0
						 or bra.type = 2
						 or bra.type = 4
						 or bra.type = 6
						 or bra.type = 23);

		delete from br_audit_cycle_assign
			  where audit_cycle_assign_id in
					   (select aca.audit_cycle_assign_id
						  from    br_audit_cycle_assign aca
							   join
								  tempacc t
							   on aca.acct_id = t.acct_id
								  and aca.orig_id = t.orig_id
						 where t.acct_id = g_acct_id and t.orig_id between g_min_orig_id and g_max_orig_id);

		delete from br_audit bra
			  where bra.acct_id = g_acct_id
					and (   bra.type = ca_cycle_assign
						 or bra.type = ca_cycle_assign_reject
						 or bra.type = ca_cycle_assign_reset)
					and exists
						   (select 1
							  from tempacc
							 where acct_id = bra.acct_id and audit_id = bra.audit_id
								   and orig_id between g_min_orig_id
												   and g_max_orig_id)
					and not exists
							   (select 1
								  from br_audit_cycle_assign baca
								 where acct_id = g_acct_id
									   and baca.audit_id = bra.audit_id);

		delete from br_notes bn
			  where (bn.acct_id, bn.note_group) in
					   (select tp.acct_id, tp.note_group
						  from tempacc tp
						 where tp.record_id between g_min_record_id
												and g_max_record_id)
					and bn.note_group > 0 and bn.acct_id = g_acct_id;

		delete from br_data_extra brde
			  where brde.acct_id = g_acct_id
					and brde.record_id between g_min_record_id and g_max_record_id
					and exists
						   (select 'x'
							  from tempacc
							 where acct_id = brde.acct_id
								   and record_id = brde.record_id);

		delete from br_data brd
			  where brd.acct_id = g_acct_id
					and brd.record_id between g_min_record_id and g_max_record_id
					and exists
						   (select 'x'
							  from tempacc
							 where acct_id = brd.acct_id
								   and record_id = brd.record_id);

		DELETE  FROM brt_purge_orphan_records where acct_id = g_acct_id and exec_flag = 1;
		DELETE  FROM tempacc where acct_id = g_acct_id;
		COMMIT;
	END LOOP;
	CLOSE acct_cursor;

    v_success := 1;
    p_success := v_success;

    exception
    when others then
		ROLLBACK;
		update brt_purge_orphan_records set exec_flag = 0 where exec_flag = 1;
		commit;
		p_errReason := 'pr_purge_orphan_records';
		pkg_bs_log_event.pr_log_error (p_instance_id => 0
                                    ,p_severity_id => 0
                                    ,p_message => 'Error calling pkg_br_purge.pr_purge_orphan_records'
                                    ,p_extra_text => 'Server Error '||to_char(SQLCODE)||' '||SQLERRM
                                    ,p_category_id => 1
                                    ,p_success => v_success
                                    );
		p_success := 0;     -- error returned, exception not re-raised as caller does not handle exceptions

	END pr_purge_orphan_records;

end pkg_br_purge;