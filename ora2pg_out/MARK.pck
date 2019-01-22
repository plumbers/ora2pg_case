CREATE OR REPLACE PACKAGE MARK IS


  -- �������� !
  -- ��� �-��� �������� � ����� �����������
  -- �����������:
  --   CHANGE_IMG_STATUS
  --   Add_Record_To_Media
  type TSmalStrs is table of varchar2(100) index by binary_integer;
  type TLargeStrs is table of varchar2(2000) index by binary_integer;
  type TNumbers is table of number index by binary_integer;

  FUNCTION Do_KatName(art_rodname varchar2, art_idkl integer, art_predl varchar2, art_inic varchar2) RETURN varchar2;
--  FUNCTION Do_KatName_uni(art_rodname varchar2, art_idkl integer, art_predl varchar2, art_inic varchar2) RETURN varchar2;
  PROCEDURE renum_qatr;

  FUNCTION MED_IS_USED (tecmed INTEGER) RETURN INTEGER;
  PROCEDURE REPLACE_IMG( medcode NUMBER, new_medcode NUMBER);
  FUNCTION FIND_MAIN_IMG( p_medcode NUMBER, p_kversion number :=2000 ) RETURN NUMBER;
  PROCEDURE CHANGE_IMG_STATUS( p_medcode NUMBER, new_status NUMBER, new_main_medcode NUMBER);
  FUNCTION get_img_fn_by_paicode( p_paicode number, only_name number:=0 ) RETURN varchar2;

  -- ����������:
  -- 0 - ��� ������
  -- 1 - ������
  -- �������� � ��������� ����������
  FUNCTION Add_Record_To_Media
    (
  p_id_bas NUMBER,
  p_source_file VARCHAR2,
  p_name VARCHAR2,
    p_filename VARCHAR2,
  p_ext VARCHAR2,
  p_pyramida NUMBER,
    p_filesize NUMBER,
  p_filecsum NUMBER,
  p_server_id VARCHAR2,
  p_status NUMBER,
    p_img VARCHAR2,          -- In HEX format
  names TSmalStrs,             -- �������� � �������� ���������� ��� Bind'����
  types TSmalStrs,
  vals TLargeStrs,
  prev_medcode NUMBER           -- ������ �� ������� �����������
  ) RETURN VARCHAR2;

FUNCTION CopyRecord( p_tipo NUMBER, p_id_bas NUMBER, p_ignory_table VARCHAR2 ) RETURN NUMBER;
FUNCTION GetLevelsCount( width pls_integer, height pls_integer ) RETURN pls_integer;


FUNCTION FilesInDbIsGood RETURN BOOLEAN;
-- Public type declarations
CURSOR cCompileErr IS
   SELECT  fname, ftype, xname, fdate, rpad('����� ������',1000) As err  FROM s_files a;
SUBTYPE  cCompileErr_rec IS cCompileErr%ROWTYPE;
type cCompileErr_ref is ref cursor return cCompileErr_rec;
PROCEDURE GetCompileError( c IN OUT cCompileErr_ref );

FUNCTION GetImgFile( p_id_bas number, with_path_flag number:=0 ) RETURN varchar2;
FUNCTION GetPyrFile( p_id_bas number, with_path_flag number:=0 ) RETURN varchar2;

PROCEDURE Test;
PROCEDURE Test_Out( a IN OUT number);
FUNCTION Test_Add( a number, b number) RETURN number;

FUNCTION get_img_fn_by_id(id1 integer, ret_pyramid integer:=0) RETURN varchar2;

-- ����������� ������� � ���������� ��� �����. �������� �������
-- :/\ �� ���� � ������� *?_ �� ������
FUNCTION CorrectFileName( s varchar2 ) RETURN varchar2;

FUNCTION TrimSpecChars( param varchar2 ) RETURN varchar2;

FUNCTION GetUtf8Text( id varchar2 ) RETURN varchar2;
PROCEDURE SetUtf8Text( id varchar2, s varchar2 );

END;
/
CREATE OR REPLACE PACKAGE BODY MARK
IS
-- 04.10.2018 SR Add_Record_To_Media - ��������� ���������� h_server
-- 27.08.2018 YL get_img_fn_by_id - ���������� � DB_UTIL. �����  ��������� ��� �������� ������������� c Forms, ������ rotation
-- 27.06.2018 YL get_img_fn_by_id - �������� ������ ��������� ��������� ����������� (�� ��� ��� ��� ������� �2000)
-- 15.06.2018 PZ get_img_fn_by_id - �������� ���� ��������
-- 12.05.2016 SR � CorrectFileName substr ������� �� substrb
-- 25.11.2015 SR � Add_Record_To_Media ����� MEDIA ������� �� user.MEDIA (������ � KUKMOR ORA-01031: ���������� ������������)
-- 06.08.2014 SR �������� �������� � FIND_MAIN_IMG -- ������ �����: 2000 - KAMIS2000, 5 - KAMIS5
-- 25.09.2012 SS ���� ������ � FUNCTION CopyRecord (������ �� ������ no_data_found) :(
-- 15.09.2005 ���. �-��� CorrectFileName
-- �������� ������ "
-- 20.07.2005 ��������� �-��� GetUtf8Text, SetUtf8Text
-- 28.03.2005 ��������� �-��� TrimSpecChars
-- ������� ������� CHR(9),CHR(10),CHR(13) � ����� ������.
-- 03.09.2004 ��������� �������� �� ��� ����� (��� ����, ��� ����������� ������)
-- 15.05.2004 ��������� �-��� CorrectFileName
-- 02.07.2003 ��������� ��������� ��� �-��� GET_IMG_FN_BY_ID
-- 21.02.2003 � ������ �� ������ ������ ��������� ��������� �������
--   bin2. � ������, � ���� auto_generate=1 ������ ���� ���������
--   �������: fname2, bin2
-- 16.02.2004 ������� ���������� usrname, ������ ��� DB_DDL.usrname
-- 03.02.2004 ������� ������ �� KLUSER
-- 16.01.2003 � �-��� FIND_MAIN_IMG ��������� ���������
--   ������� 3 (video/audio)
-- 22.11.2002 ��������� ��������� ������ � ������������� ������
-- 13.11.2002. ������ ������� !

-- 22.08.2002 �-��� GET_IMG_FN_BY_PAICODE ���������� �������� (����
-- ��� ��������), ���� �������� ���  - �������� ����
-- 17.07.2002 ������� � all_tab_columns  � ��������� usrname
-- 13.06.2002 ��������� � cursor'� ���
-- ���������� �������
-- ftype<>'DIR' �������� ��
-- (ftype<>'DIR' OR ftype is null)
-- �.�. ���� ftype==null ��� ����� ������
-- ���� ��Upload'����� ������.
-- 11.06.2002 ��� ����� � �����������
-- ��������� �-���
-- GetImgFile ��������� ����� ����� ���������
-- ����� (�� ��������)
-- GetPyrFile ��������� ����� ����� � ���������
-- 4.03.2002 ��������� �-��� ��� ��������
-- ������ (��������� "�� ��������������")
-- ������� ����������
-- 10.12.2001 ��������� �-��� ��� ������ �
-- ����������� �������
--    FileInDbIsGood
-- 19.10.2001 �������� �������
-- 15.10.2001 ��������� �-���
-- ��� ���������� ���������� � ���� MEDIA �����
-- DBMS_SQL, ����. ������� ����� ������������� �����
-- ���������� ����� ������.
-- 4.10.2001 ��������� ������ �����
-- ���������� ���������� +
-- ������ ������ � MEDIA ����������
-- ������ ����� VARCHAR2, � ���� HEX �����.
usrname VARCHAR2(30);
my_blob BLOB;
/* ������������ ��������� ����������� (item WAY) ��� �������� */
FUNCTION Do_KatName(art_rodname VARCHAR2, art_idkl INTEGER, art_predl VARCHAR2, art_inic VARCHAR2) RETURN VARCHAR2 IS
    res VARCHAR2(500):='';
 BEGIN
    IF art_rodname IS NULL THEN
        res:='';
    ELSIF art_idkl=1 THEN
        res:='�� '||art_rodname||' '||art_inic;
    ELSE
        res:=art_predl||' '||art_rodname;
    END IF;
 RETURN res;
END Do_KatName;

/* ������������� S_qatr �� KART */
PROCEDURE renum_qatr IS
i INTEGER;
CURSOR cr IS
 SELECT DISTINCT
 A.idtab,
 A.idatr idatr,
 MAX(SUBSTR(zakl,5)*1000000+K.num) num,
 MIN(A.ID) ID,
 0 tipo
 FROM s_qatr A, kart K
 WHERE A.idatr=K.idfr AND
 A.idtab=DECODE(A.attr_type,'NN',K.id_svt,'1N',K.id_svt,K.idtab) AND
 attr_type IN ('D','D2','D4','NN','1N','N1','N','C')  AND
 A.attr_type != 'VAR'
GROUP BY A.idtab,idatr
ORDER BY 1,3;
BEGIN
i:=0;

FOR c1 IN cr LOOP
    i:=i+10;
    UPDATE s_qatr set num=i
    WHERE s_qatr.ID=C1.ID;
END LOOP;

END;

/* **************************************************** */
/*               ������ � �������������                 */
/* **************************************************** */

---------------------------------------
--���������� ��� ���� � ������, �������� �������� �� ������ '\'
FUNCTION ADD_PATH(in_path1 VARCHAR2, path2 VARCHAR2) RETURN VARCHAR2 IS
  path1 VARCHAR2(1000);
BEGIN
  path1:=in_path1;
  IF LENGTH(path2)=0 THEN
      RETURN path1;
  END IF;
  IF SUBSTR( path1, LENGTH(path1) )='\' AND SUBSTR( path2, 1, 1 )='\' THEN
      RETURN SUBSTR( path1, LENGTH(path1-1) )||path2;
  ELSIF SUBSTR( path1, LENGTH(path1) )='\' OR SUBSTR( path2, 1, 1 )='\' THEN
      RETURN path1||path2;
  ELSE
      RETURN path1||'\'||path2;
  END IF;
END;
---------------------------------------
-- 27.08.2018 YL ���������� � DB_UTIL. �����  ��������� ��� �������� ������������� c Forms, ������ rotation

-- ���������� ��� �����, ���������� � ������ �������
-- � ����� MEDIA
-- Parameters:
--      idl - ID_BAS � MEDIA
--      ret_pyr:
--              0 - ���������� ���� �����������
--              1 - � ������, ���� ���� ��������,
--              ���������� ��������. ��� ������ ���
--              ��� I-net ���������.
FUNCTION get_img_fn_by_id(id1 INTEGER, ret_pyramid INTEGER) RETURN VARCHAR2 IS
-- idl - ��� � ������� MEDIA
  fn VARCHAR2(1000);
  filename VARCHAR2(250);
  ext VARCHAR2(250);
  server_id NUMBER(10);
  pyramida NUMBER(10);
  PATH VARCHAR2(250);
  v_rotation NUMBER;
BEGIN
  if id1 is null then
    return null;
  end if;
    SELECT
      media.filename,
      media.ext,
      media.server_id,
      media.pyramida,
      s.PATH
    INTO filename, ext, server_id, pyramida, PATH
  FROM
    media media,
    s_img_server s
  WHERE
    media.server_id=s.ID AND media.id_bas=id1;

  IF pyramida>0 and ret_pyramid=1 THEN
     NULL;
  ELSE
    BEGIN
        SELECT
           media.filename,
            media.ext,
           media.server_id,
         media.pyramida,
         s.PATH
        INTO filename, ext, server_id, pyramida, PATH
      FROM med_med A, media media, s_img_server s
      WHERE
        media.server_id=s.ID AND media.id_bas=A.medcode AND
        A.medcode2=id1 AND
        media.status=2;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      NULL;
    END;
  END IF;

  IF pyramida>0 THEN
      ext:='\ac001001.spf';
      IF v_rotation IS NOT NULL THEN
         ext := ext||'?rotation='||v_rotation;
      END IF;
  END IF;

  fn:=ADD_PATH( PATH, filename)||ext;
  RETURN fn;
EXCEPTION
  WHEN OTHERS THEN
    RETURN NULL;
END;


---------------------------------------
--�������� ������������� ������� �����������
FUNCTION MED_IS_USED (tecmed INTEGER) RETURN INTEGER IS
--tecmed - ������� ��� ����� MEDIA
--����������: 0 - ����� �� ������������
--         �� 0 - ���� ������ �� ������ ������
  cou INTEGER;
  sql_comm VARCHAR2(1000);
BEGIN
  cou:=0;
  FOR cc1 IN (SELECT DISTINCT idatr, idtab FROM s_qatr WHERE id_tab_r='MEDIA') LOOP
    sql_comm:='SELECT COUNT(*) FROM '||cc1.idtab||' WHERE '||cc1.idatr||'='||tecmed;
    cou:=UTILS.Select_Value( sql_comm );
    IF cou<>0 THEN
      EXIT;
    END IF;
  END LOOP;
  RETURN cou;
END MED_IS_USED;

-----------------------------------------------
-- ������ ������ ����������� � �� �� ������
-- �� ���� ������ �������
PROCEDURE REPLACE_IMG( medcode NUMBER, new_medcode NUMBER) IS
  sql_comm VARCHAR2(1000);
  ret INTEGER;
BEGIN
  -- ������ ������ - ������ ������
  FOR cc1 IN (SELECT DISTINCT idatr, idtab FROM s_qatr WHERE id_tab_r='MEDIA') LOOP
    sql_comm:='UPDATE '||cc1.idtab||' SET '||cc1.idatr||'='||new_medcode||' WHERE '||cc1.idatr||'='||medcode;
    EXECUTE IMMEDIATE sql_comm;
  END LOOP;
END;

-- ----------------------------------------------------------------
-- ��� ��������� ����������� � ����� MEDIA ���������� ��������� � ���
-- ����������������� �� �������� 1. ��� ��� ������ (���� � ���� status � ��� 1)
-- ����  ����������� ��� ���������� NULL
-- -----------------------------------------------------------------
FUNCTION FIND_MAIN_IMG( p_medcode NUMBER
                       ,p_kversion number :=2000 -- ������ �����: 2000 - KAMIS2000, 5 - KAMIS5
                        ) RETURN NUMBER IS
  my_status NUMBER;
  my_medcode NUMBER;
  v_kversion number;
BEGIN
  v_kversion := nvl(p_kversion,2000);
  IF p_medcode<1 THEN       -- ����������� ���
    RETURN p_medcode;
  END IF;
  SELECT status INTO my_status FROM media WHERE id_bas=p_medcode;
  IF my_status=1 OR (my_status=3 and v_kversion =2000) THEN
    RETURN p_medcode;
  END IF;
  BEGIN
    if p_kversion = 5
    then
        SELECT A.medcode2 INTO my_medcode FROM med_med A, media b WHERE A.medcode=p_medcode AND A.medcode2=b.id_bas AND b.status=1;
    else
        SELECT A.medcode INTO my_medcode FROM med_med A, media b WHERE A.medcode2=p_medcode AND A.medcode=b.id_bas AND b.status=1;
    end if;

  EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
  END;
  RETURN my_medcode;
END FIND_MAIN_IMG;


-- ----------------------------------------------------------------
-- ������ status � �����������
-- ������ ������� (�� �������� 1 ����������� new_main_medcode)
-- ������������� ������� ������ � med_med
-- new_main_medcode  <---> p_medcode
-- ���� �������� � ��������� ����������
-- �� �������� � ��������� ���������� (���-��� �������� ��������� � Forms'��
-- ������ � ���� �-���, ����� ���������� �� ������, ������� ���� ��������������
-- ����-��)
PROCEDURE CHANGE_IMG_STATUS( p_medcode NUMBER, new_status NUMBER, new_main_medcode  NUMBER) IS
  PRAGMA autonomous_transaction;
BEGIN
  IF p_medcode>0 THEN
     REPLACE_IMG( p_medcode, new_main_medcode );
     UPDATE media SET status=new_status WHERE id_bas=p_medcode;
     INSERT INTO med_med (ID, medcode, medcode2) VALUES ( seq_s.NEXTVAL, new_main_medcode, p_medcode );
     COMMIT;
  END IF;
END;
/*
FUNCTION get_img_fn_by_paicode( p_paicode number, only_name number ) RETURN varchar2 IS
  typimg1 NUMBER;
  my_medcode NUMBER;
  my_name VARCHAR2(1000);
BEGIN
  my_name:='';
  BEGIN
    SELECT MIN(id_bas) INTO typimg1 FROM KLASS WHERE ID_KL=5;
    IF only_name=1 THEN
       SELECT media.filename||media.ext INTO my_name
       FROM PAI_MED, MEDIA
       WHERE paicode=p_paicode AND typimg=typimg1 AND medcode=id_bas;
       RETURN my_name;
    ELSE
       SELECT medcode INTO my_medcode
       FROM PAI_MED
       WHERE paicode=p_paicode AND typimg=typimg1;
       RETURN get_img_fn_by_id( my_medcode );
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
  END;
END;
*/

FUNCTION get_img_fn_by_paicode( p_paicode NUMBER, only_name NUMBER ) RETURN VARCHAR2 IS
  typimg1 NUMBER;
  my_medcode NUMBER;
  my_name VARCHAR2(1000);
  my_pyramida NUMBER;
BEGIN
  my_name:='';
  BEGIN
    SELECT MIN(id_bas) INTO typimg1 FROM KLASS WHERE ID_KL=5;
    SELECT media.id_bas, media.pyramida
      INTO my_medcode, my_pyramida
      FROM pai_med, media
      WHERE pai_med.paicode=p_paicode AND pai_med.typimg=typimg1 AND pai_med.medcode=media.id_bas;
    IF my_pyramida=1 THEN
      NULL;
    ELSE
        BEGIN
          SELECT c.id_bas
            INTO my_medcode
            FROM media A, med_med b, media c
            WHERE A.id_bas=my_medcode AND A.id_bas=b.medcode AND b.medcode2=c.id_bas AND c.status=2;
        EXCEPTION WHEN NO_DATA_FOUND THEN
          NULL;
        END;
    END IF;

    IF only_name=1 THEN
       SELECT media.filename||media.ext INTO my_name
       FROM MEDIA
       WHERE id_bas=my_medcode;
       RETURN my_name;
    ELSE
       RETURN get_img_fn_by_id( my_medcode );
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
  END;
END;

-- ����������:
-- 0 - ��� ������
-- 1 - ������
-- �������� � ��������� ����������
FUNCTION Add_Record_To_Media
  (
  p_id_bas NUMBER,
  p_source_file VARCHAR2,
  p_name VARCHAR2,
    p_filename VARCHAR2,
  p_ext VARCHAR2,
  p_pyramida NUMBER,
    p_filesize NUMBER,
  p_filecsum NUMBER,
  p_server_id VARCHAR2,
  p_status NUMBER,
    p_img VARCHAR2,          -- In HEX format
  names TSmalStrs,             -- �������� � �������� ���������� ��� Bind'����
  TYPES TSmalStrs,             -- 'v', 'd', 'n'
  vals TLargeStrs,
  prev_medcode NUMBER      -- ������ �� ������� �����������
  ) RETURN VARCHAR2 IS
  PRAGMA autonomous_transaction;
  raw_buffer LONG RAW; -- (32766);
  sql_comm VARCHAR2(2000);
  fields_list VARCHAR2(4000);
  cur INTEGER;
  i NUMBER;
  res NUMBER;
  v_h_server number;
BEGIN
  raw_buffer:=HEXTORAW(p_img);

  begin
       execute immediate 'select h_server from s_img_server  where id = :p_server_id' into v_h_server using p_server_id;
       exception when others then null;
  end;     
  execute immediate 'INSERT INTO '||DB_DDL.usrname||'.media
      (id_bas, source_file, NAME,
      filename, ext, pyramida,
         filesize, filecsum, server_id, status,
    filecdate,
      img, h_server)
      VALUES
      (:p_id_bas, :p_source_file, :p_name,
      :p_filename, :p_ext, :p_pyramida,
      :p_filesize, :p_filecsum, :p_server_id, :p_status,
    SYSDATE,
      :raw_buffer, :h_server )'
     using p_id_bas, p_source_file, p_name,
      p_filename, p_ext, p_pyramida,
      p_filesize, p_filecsum, p_server_id, p_status,
      raw_buffer, v_h_server ;

  /*INSERT INTO media
      (id_bas, source_file, NAME,
      filename, ext, pyramida,
         filesize, filecsum, server_id, status,
    filecdate,
      img)
      VALUES
      (p_id_bas, p_source_file, p_name,
      p_filename, p_ext, p_pyramida,
      p_filesize, p_filecsum, p_server_id, p_status,
    SYSDATE,
      raw_buffer );*/
  IF names IS NOT NULL AND names.COUNT>0 THEN
/*
    IF names.count<>vals.count THEN
      ROLLBACK;
      RETURN 'Field names and values lists has other length.';
    END IF;
*/
      cur := DBMS_SQL.OPEN_CURSOR;
    -- ��������� ������ �������������� �����, �������� �������� ����� DBMS_SQL
    -- ������� ������ �������������� ����� ��� �������
    fields_list:=NULL;
    FOR i IN 1..names.COUNT LOOP

      IF vals.EXISTS(i) AND vals(i) IS NOT NULL THEN
        IF TYPES(i) IN ('c','v') THEN
          fields_list:=names(i)||'=:'||names(i);
        ELSIF TYPES(i) IN ('n') THEN
          fields_list:=names(i)||'=TO_NUMBER(:'||names(i)||')';
        ELSIF TYPES(i) IN ('d') THEN
          fields_list:=names(i)||'=TO_DATE(:'||names(i)||',''DD.MM.YYYY'')';
        ELSIF TYPES(i) IN ('dt') THEN
          fields_list:=names(i)||'=TO_DATE(:'||names(i)||',''DD.MM.YYYY HH24:MI:SS'')';
        END IF;
      ELSE
        fields_list:=names(i)||'=NULL';
      END IF;

      -- �������� SQL-�������
      sql_comm:='UPDATE '||DB_DDL.usrname||'.media SET '||fields_list||' WHERE id_bas='||p_id_bas;  -- , :img
      -- Prepare
      DBMS_SQL.PARSE(cur, sql_comm, DBMS_SQL.NATIVE);
      -- ���������� BIND-����������
      IF TYPES(i) IN ('c','v', 'n','d', 'dt') AND vals.EXISTS(i) AND vals(i) IS NOT NULL THEN
         DBMS_SQL.BIND_VARIABLE ( cur, names(i), vals(i) );
      END IF;

          -- Execute
      BEGIN
           /*
             ���������� ������� ����� ��������� ���������� ��-�� ������������� �������������� ��������� �����.
             ��� ������� �� �������� ����������� �����������.
             �� ������ ������ ������ ����������� ������ � ��������� �.
             Added by mac, 25.04.2009
           */
          res:=DBMS_SQL.EXECUTE( cur );
      EXCEPTION WHEN others THEN
        NULL;
      END;

    END LOOP;

      DBMS_SQL.CLOSE_CURSOR( cur );
  END IF;
  IF prev_medcode IS NOT NULL THEN
    INSERT INTO med_med (ID, medcode, medcode2 ) VALUES ( seq_s.NEXTVAL, prev_medcode, p_id_bas );
  END IF;
  COMMIT;
  RETURN NULL;
EXCEPTION WHEN OTHERS THEN
  IF DBMS_SQL.IS_OPEN( cur ) THEN
    DBMS_SQL.CLOSE_CURSOR( cur );
  END IF;
  ROLLBACK;
  RETURN DBMS_UTILITY.FORMAT_ERROR_STACK || ' ' ||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
         ||' p_filename, p_ext= '||p_filename||'/'||p_ext;
END Add_Record_To_Media;

-- �-��� �������� ���� ������ � ������ ����� � ID_BAS, �������
-- ������������ �� tipo
-- ignory_table - �������, ����� � ������� ������������,
--   ��������, ���� ����������� ����������� ��� �����
--   ������������ �������� ��� ���������� �����������,
--   ���������� ����� � MEDIA ������ ���, �����, �����
--   ����������� ignory_table='MEDIA'
-- ����������: ����� ����� ������
-- P.S. �� ���������� ������� kart_copy � KART'�
FUNCTION CopyRecord( p_tipo         NUMBER,
                     p_id_bas       NUMBER,
                     p_ignory_table VARCHAR2 )
  RETURN NUMBER
IS
  maintab    VARCHAR2(100);
  sql_comm1  VARCHAR2(32767);
  sql_comm2  VARCHAR2(32767);
  first_rec  BOOLEAN;
  new_id_bas NUMBER;
  BUFFER_STR VARCHAR2(32767);
BEGIN
     /* ����������, ����� ������� ��� ������� ���� - '�������' */
     SELECT UPPER(idtab)
       INTO maintab
       FROM kltipo
      WHERE id_bas = p_tipo;
     ---
     /* ���� �� ���� �����, ������� ����� � ������� ������� */
     IF maintab='PAINTS'
     THEN
         SELECT SEC_PAINTS.NEXTVAL
           INTO new_id_bas
           FROM dual;
     ELSE
         SELECT SEQ_KA.NEXTVAL
           INTO new_id_bas
           FROM dual;
     END IF;
     ---
     sql_comm1:='INSERT INTO '||maintab||' ( id_bas';
     sql_comm2:=' ) SELECT '||new_id_bas||' AS id_bas';
     ---
     -- ����� ������� ������ ���������� ���� �����:
     -- LONG, BLOB, CLOB, LONG RAW
     FOR c IN (SELECT *
                 FROM sys.all_tab_columns
                WHERE     table_name  =  maintab
                      AND column_name <> 'ID_BAS'
                      AND data_type NOT IN ('LONG', 'BLOB', 'CLOB', 'LONG RAW') )
     LOOP
         sql_comm1:=sql_comm1||', '||c.column_name;
         sql_comm2:=sql_comm2||', '||c.column_name;
     END LOOP;
     ---
     sql_comm1:=sql_comm1||sql_comm2||' FROM '||maintab||' WHERE id_bas='||p_id_bas;
     --DBMS_OUTPUT.PUT_LINE(sql_comm1);
     EXECUTE IMMEDIATE sql_comm1;
     ---
     -- ������� ���� LONG (BLOB, CLOB, LONG RAW-��� ������ �� ���������)
     FOR c IN (SELECT *
                 FROM sys.all_tab_columns
                WHERE     table_name  =  maintab
                      AND column_name <> 'ID_BAS'
                      AND data_type IN ('LONG') )
     LOOP
         ---
         BUFFER_STR := NULL;
         ---
         BEGIN
              sql_comm1:='SELECT '||c.column_name||' FROM '||maintab||' WHERE id_bas='||p_id_bas;
              --DBMS_OUTPUT.PUT_LINE(sql_comm1);
              EXECUTE IMMEDIATE sql_comm1 INTO BUFFER_STR;
         EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
             BUFFER_STR := NULL;
         END;
         ---
         IF BUFFER_STR IS NOT NULL
         THEN
             sql_comm1:='UPDATE '||maintab||' SET '||c.column_name||'=:V1  WHERE id_bas='||new_id_bas;
             --DBMS_OUTPUT.PUT_LINE(sql_comm1);
             EXECUTE IMMEDIATE sql_comm1 USING IN BUFFER_STR;
         END IF;
         ---
     END LOOP;
     ---
     -- ���� �� ���� �����, ������� ����� � �������� �������
     -- ����� ������, ����������� � ignory_table
     -- ����, ���������� � ������� ������� �� KART'�, � ����������
     -- � �������� ������� �� all_tab_columns
     FOR c1 IN (SELECT DISTINCT UPPER(idtab) idtab, id_sv2
                  FROM kart
                 WHERE     tipo        =  p_tipo
                       AND idtab       <> maintab
                       AND UPPER(idfr) <> 'ID_BAS'
                       AND id_sv2      IS NOT NULL
                       AND idtab NOT IN
                                       (SELECT DISTINCT idtab
                                          FROM s_qatr
                                         WHERE s_qatr.id_tab_r = p_ignory_table)
                       AND idtab IN ( SELECT TABLE_NAME FROM USER_TABLES)
               )
     LOOP
         sql_comm1:='INSERT INTO '||c1.idtab||' ( id';
         sql_comm2:=' ) SELECT SEQ_S.nextval';
         /* ���� �� ���� ���������� �����, � �������� ������ */
         FOR c2 IN (SELECT *
                      FROM sys.all_tab_columns
                     WHERE     owner       =  DB_DDL.usrname
                           AND table_name  =  UPPER(c1.idtab)
                           AND column_name <> 'ID'
                           AND data_type NOT IN ('LONG', 'BLOB', 'CLOB', 'LONG RAW') )
         LOOP
             sql_comm1:=sql_comm1||', '||c2.column_name;
             IF c2.column_name = c1.id_sv2
             THEN
                 sql_comm2:=sql_comm2||', '||new_id_bas||' AS '||c2.column_name;
             ELSE
                 sql_comm2:=sql_comm2||', '||c2.column_name;
             END IF;
         END LOOP;
         ---
         sql_comm2:=sql_comm2||' FROM '||c1.idtab||' WHERE '||c1.id_sv2||'='||p_id_bas;
         ---
         --    IF c1.usl_we is not null THEN
         --      sql_comm2:=sql_comm2||' AND '||c1.usl_we;
         --    END IF;
         --    IF c1.attr_func is not null THEN
         --      sql_comm2:=sql_comm2||' AND attr_func='||c1.attr_func;
         --    END IF;
         ---
         sql_comm1:=sql_comm1||sql_comm2;
         --DBMS_OUTPUT.PUT_LINE(sql_comm1);
         EXECUTE IMMEDIATE sql_comm1;
     END LOOP;
     ---
     RETURN new_id_bas;
     ---
END CopyRecord;

------------------------------------------
-- ���������� ������������ ������� ��������,
-- ������ ������������ �� ������� ��������� �����
FUNCTION GetLevelsCount( width PLS_INTEGER, height PLS_INTEGER ) RETURN PLS_INTEGER IS
  mdx CONSTANT NUMBER:=720;
  mdy CONSTANT NUMBER:=576;
    R1 NUMBER;
  R2 NUMBER;
    R NUMBER;

  LEVELS PLS_INTEGER;
BEGIN
    R1:=width/mdx;
    R2:=height/mdy;
    IF R1>R2 THEN
    R:=R1;
  ELSE
    R:=R2;
  END IF;

    IF R>1 THEN
        LEVELS:=4;
        WHILE R>3 LOOP
            LEVELS:=LEVELS+1;
            R:=R/2;
        END LOOP;
    ELSE
        LEVELS:=3;
        WHILE R<1 AND LEVELS>1 LOOP
            LEVELS:=LEVELS-1;
            R:=R*2;
        END LOOP;
    END IF;
  RETURN LEVELS;
END;
-- ���������� ������ ��������� ����� S_FILES
-- ������� ����������
-- ���� ������ �-��� ������� ������ ������ - ������ ��������� ��
-- ������� ��������������
PROCEDURE GetCompileError( c IN OUT cCompileErr_ref ) IS
BEGIN
  OPEN c FOR
  -- ��� ���������������� ������
         SELECT  fname, ftype, xname, fdate, '��� ���������������� ������' AS err  FROM s_files A
         WHERE (A.auto_compile=1 OR A.auto_generate=1) AND A.xname IS NOT NULL AND
         NOT EXISTS (SELECT * FROM s_files b WHERE b.fname=A.xname)
  -- ��� Upload'�� ������
     UNION
         SELECT fname, ftype, xname, fdate, '��� ������' AS err FROM s_files A
         WHERE (ftype<>'DIR' OR ftype IS NULL) AND (fdate IS NULL OR bin IS NULL OR fsize<1)
  -- ��� ����������� ������ ��� �������� ���� (��� FMB, ��� MMB - �� � ���� �� ������)
     UNION
         SELECT fname, ftype, xname, fdate, '��� ����������� ������ ��� ����' AS err FROM s_files A
         WHERE auto_generate=1 AND ftype='FMB' AND (bin2 IS NULL OR fname2 IS NULL)
  -- ������, ������� ������ ������� ����������
     UNION
         SELECT  fname, ftype, xname, fdate, '�������� ����� ����������������� �����' AS Err FROM S_FILES
         WHERE xname IS NOT NULL AND (auto_compile=1 OR auto_generate=1) AND
         fdate > (
                  SELECT MIN(A.fdate) FROM S_FILES A
                  WHERE EXISTS (SELECT xname FROM S_FILES WHERE xname=A.fname
                  AND (auto_compile=1 OR auto_generate=1) )
                  );
END;

------------------------------------------------
-- ���������� ������� - ���� � ������� S_FILES
-- ����� ��������� ���������������� ����������
-- ��� ���� �������� ������ (����� �����������
-- ������������� PAINTS.FMB, ARTIST.FMB � �.�.)
FUNCTION FilesInDbIsGood RETURN BOOLEAN IS
  c1 cCompileErr_ref;
  rec cCompileErr_rec;
  flag BOOLEAN;
BEGIN
  GetCompileError( c1 );
  FETCH c1 INTO rec;
  IF c1%NOTFOUND THEN
    flag:=TRUE;      -- ��� ������
  ELSE
    flag:=FALSE;     -- ������
  END IF;
  CLOSE c1;
  RETURN flag;
END FilesInDbIsGood;


FUNCTION GetImgFile( p_id_bas NUMBER, with_path_flag NUMBER:=0 ) RETURN VARCHAR2 AS
  my_filename VARCHAR2(1000);
  my_pyramida NUMBER(10);
  my_server_id NUMBER(10);
  my_serverpath VARCHAR2(1000);
BEGIN
  SELECT filename||ext, pyramida, server_id  INTO my_filename,my_pyramida, my_server_id  FROM media WHERE id_bas=p_id_bas;
  IF my_pyramida=1 THEN
    RETURN '';
  END IF;
  IF with_path_flag=1 THEN
    SELECT PATH INTO my_serverpath FROM s_img_server WHERE ID=my_server_id;
    my_filename:=my_serverpath||'\'||my_filename;
  END IF;
  RETURN my_filename;
  EXCEPTION WHEN OTHERS THEN
    RETURN '';
END;

FUNCTION GetPyrFile( p_id_bas NUMBER, with_path_flag NUMBER:=0 ) RETURN VARCHAR2 IS
  my_filename VARCHAR2(1000);
  my_pyramida NUMBER;
  my_server_id NUMBER(10);
  my_serverpath VARCHAR2(1000);
BEGIN
  SELECT filename, pyramida, server_id INTO my_filename, my_pyramida, my_server_id FROM media WHERE id_bas=p_id_bas;
  IF my_pyramida=1 THEN
    NULL;
  ELSE
    BEGIN
      SELECT c.filename, c.pyramida, c.server_id
        INTO my_filename, my_pyramida, my_server_id
        FROM media A, med_med b, media c
        WHERE A.id_bas=p_id_bas AND A.id_bas=b.medcode AND b.medcode2=c.id_bas AND c.status=2;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      RETURN '';
    END;
  END IF;
  IF with_path_flag=1 THEN
    SELECT PATH INTO my_serverpath FROM s_img_server WHERE ID=my_server_id;
    my_filename:=my_serverpath||'\'||my_filename;
  END IF;
  RETURN my_filename;
  EXCEPTION WHEN OTHERS THEN
    RETURN '';
END;

PROCEDURE Test IS
BEGIN
  NULL;
END;

PROCEDURE Test_Out( A IN OUT NUMBER) IS
BEGIN
  A:=A*A;
END;

FUNCTION Test_Add( A NUMBER, b NUMBER) RETURN NUMBER IS
BEGIN
  RETURN A+b;
END;

FUNCTION CorrectFileName( s VARCHAR2 ) RETURN VARCHAR2 IS
  fn VARCHAR2(200);
BEGIN
  fn := RTRIM( LTRIM( SUBSTRB( s, 1, 200 ) ) );
  fn := REPLACE( fn, ':', '-' );
  fn := REPLACE( fn, '\', '-' );
  fn := REPLACE( fn, '/', '-' );
  fn := REPLACE( fn, '*', ' ' );
  fn := REPLACE( fn, '?', ' ' );
  fn := REPLACE( fn, '_', ' ' );
  fn := REPLACE( fn, '.', ' ' );
  fn := REPLACE( fn, '"', ' ' );
  IF fn IS NULL THEN
    fn := 'noname';
  END IF;
  RETURN fn;
END CorrectFileName;

FUNCTION TrimSpecChars( param VARCHAR2 ) RETURN VARCHAR2 IS
 s VARCHAR2(32000);
 c VARCHAR2(10);
 pos PLS_INTEGER;
BEGIN
  s := param;
  pos := LENGTH(s);
  WHILE pos > 0 LOOP
    c := SUBSTR( s, pos, 1 );
    IF c NOT IN ( CHR(32), CHR(9), CHR(10),
CHR(13) ) THEN
      RETURN SUBSTR( s, 1, pos );
    END IF;
    pos := pos-1;
 END LOOP;
 RETURN '';
END TrimSpecChars;


/*
  �-��� ��������� � �������� ������ � ������
  '�����' � ������� UTF8.
  ������ ������ ������������ ��� �������� ���������� �����
  ������ UTF8 � KAMIS'��.

  Note: �������� �������� ��� ������ ������ ��������
  ��������.
*/
FUNCTION GetUtf8Text( ID VARCHAR2 ) RETURN VARCHAR2 IS
  res VARCHAR(32767);
BEGIN
  EXECUTE IMMEDIATE
    'SELECT TEXT_V FROM T_UTF8 WHERE ID=:ID'
    INTO res USING ID;
  RETURN res;
END GetUtf8Text;

PROCEDURE SetUtf8Text( ID VARCHAR2, s VARCHAR2 ) IS
BEGIN
  EXECUTE IMMEDIATE
    'UPDATE T_UTF8 SET TEXT_V=:S WHERE ID=:ID'
    USING s, ID;
END SetUtf8Text;

BEGIN
NULL;
EXCEPTION WHEN OTHERS THEN
  NULL;
END;
/
