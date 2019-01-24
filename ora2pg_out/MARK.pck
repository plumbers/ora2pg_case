CREATE SCHEMA IF NOT EXISTS kamis_mark
  AUTHORIZATION CURRENT_USER;

CREATE OR REPLACE VIEW sys_all_tab_columns
  AS
    SELECT
      c.column_name,
      c.table_schema,
      c.table_name,
      c.data_type
    FROM information_schema.columns c
    WHERE c.table_schema NOT IN('pg_catalog', 'information_schema');


CREATE OR REPLACE FUNCTION HEXTORAW(text)
RETURNS bytea
AS $$
  SELECT decode($1, 'hex');
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION RAWTOHEX(text)
RETURNS bytea
AS $$
  SELECT encode($1, 'escape');
$$ LANGUAGE plpgsql;

-- ВНИМАНИЕ !
-- Две ф-ции работают в своих собственных
-- транзакциях:
--   CHANGE_IMG_STATUS
--   Add_Record_To_Media

TSmalStrs VARCHAR(100)[];
TLargeStrs VARCHAR(2000)[];

-- Public type declarations
CURSOR cCompileErr IS
  SELECT
    fname,
    ftype,
    xname,
    fdate,
    rpad('Текст ошибки', 1000) AS err
  FROM s_files a;
cCompileErr_rec record;
-- cCompileErr_ref REFCURSOR RETURN cCompileErr_rec;

/* PACKAGE BODY MARK */
-- DB_DDL.usrname === DB в ORA, в Pg аналог = схема, осатвим по-умолчанию public
-- 04.10.2018 SR Add_Record_To_Media - добавлено заполнение h_server
-- 27.08.2018 YL get_img_fn_by_id - Перенесено в DB_UTIL. Здесь  оставлено для обратной совместимости c Forms, убрано rotation
-- 27.06.2018 YL get_img_fn_by_id - Изменена логика получения исходного изображения (до сих пор был вариант К2000)
-- 15.06.2018 PZ get_img_fn_by_id - Доюавлен флаг поворота
-- 12.05.2016 SR в CorrectFileName substr заменен на substrb
-- 25.11.2015 SR в Add_Record_To_Media вызов MEDIA заменен на user.MEDIA (ошибка в KUKMOR ORA-01031: привилегий недостаточно)
-- 06.08.2014 SR добавлен параметр в FIND_MAIN_IMG -- версия КАМИС: 2000 - KAMIS2000, 5 - KAMIS5
-- 25.09.2012 SS внес правки в FUNCTION kamis_mark.CopyRecord (падало на ошибке no_data_found) :(
-- 15.09.2005 Изм. ф-ция CorrectFileName
-- добавлен символ "
-- 20.07.2005 Добавлены ф-ции GetUtf8Text, SetUtf8Text
-- 28.03.2005 добавлена ф-ция TrimSpecChars
-- убирает символы CHR(9),CHR(10),CHR(13) в конце строки.
-- 03.09.2004 добавлена проверка на тип файла (для меню, нет настроечных файлов)
-- 15.05.2004 добавлена ф-ция CorrectFileName
-- 02.07.2003 добавлены параметры для ф-ции GET_IMG_FN_BY_ID
-- 21.02.2003 в селект на запрос данных добавлена поддержка колонки
--   bin2. У файлов, у поле auto_generate = 1 должны быть заполнены
--   колонки: fname2, bin2
-- 16.02.2004 удалена переменная usrname, вместо нее DB_DDL.usrname
-- 03.02.2004 удалена ссылка на KLUSER
-- 16.01.2003 в ф-цию FIND_MAIN_IMG добавлена обработка
--   статуса 3 (video/audio)
-- 22.11.2002 Добавлена обработки ошибок в инициализацию пакета
-- 13.11.2002. Убрана отладка !

-- 22.08.2002 Ф-ция GET_IMG_FN_BY_PAICODE возврашает пирамиду (если
-- это возможно), если пирамиды нет  - исходный файл
-- 17.07.2002 Переход к all_tab_columns  с проверкой usrname
-- 13.06.2002 Изменение в cursor'е для
-- обновления системы
-- ftype!= 'DIR' заменено на
-- (ftype!= 'DIR' OR ftype is null)
-- т.к. если ftype == null все равно должны
-- быть заUpload'енные данные.
-- 11.06.2002 Для Кости в Новосибирск
-- добавлены ф-ции
-- GetImgFile получение имени файла искодного
-- файла (НЕ пирамида)
-- GetPyrFile получение имени файла с пирамидой
-- 4.03.2002 Добавлены ф-ции для контроля
-- ошибок (состояние "не скомпилировано")
-- системы обновления
-- 10.12.2001 Добавлены ф-ции для работы с
-- обновлением системы
--    FileInDbIsGood
-- 19.10.2001 Изменены статусы
-- 15.10.2001 Добавлена ф-ция
-- для добавления информации в файл MEDIA через
-- DBMS_SQL, поля. которые нужно дополнительно писаь
-- передаются через массив.
-- 4.10.2001 Добавлена работа через
-- Автономные транзакции +
-- запись иконки в MEDIA происходит
-- теперь через varchar, в виде HEX кодов.

/* Формирование источника поступления (item WAY) для каталога */
CREATE OR REPLACE FUNCTION kamis_mark.Do_KatName(
  art_rodname VARCHAR(4000), 
  art_idkl INTEGER, 
  art_predl VARCHAR(4000),
  art_inic VARCHAR(4000)
) 
RETURNS VARCHAR(4000)
AS $$
DECLARE
  res VARCHAR(500) = '';
BEGIN

  IF art_rodname IS NULL THEN
    res := '';
  ELSIF art_idkl = 1 THEN
    res := 'от '||art_rodname||' '||art_inic;
  ELSE
    res := art_predl||' '||art_rodname;
  END IF;

RETURN res;
END Do_KatName;
$$ LANGUAGE plpgsql;

/* 
Перенумерация S_qatr по KART 
*/
CREATE OR REPLACE FUNCTION kamis_mark.renum_qatr()
RETURNS VOID
AS $$
DECLARE
  i INTEGER;
  CURSOR cr IS
  SELECT DISTINCT
    A.idtab,
    A.idatr                                idatr,
    MAX(SUBSTR(zakl, 5) * 1000000 + K.num) num,
    MIN(A.ID)                              ID,
    0                                      tipo
  FROM s_qatr A, kart K
  WHERE A.idatr = K.idfr AND
        A.idtab = CASE A.attr_type
                  WHEN 'NN'
                    THEN K.id_svt
                  WHEN '1N'
                    THEN K.id_svt
                  ELSE K.idtab END AND
        attr_type IN ('D', 'D2', 'D4', 'NN', '1N', 'N1', 'N', 'C') AND
        A.attr_type != 'VAR'
  GROUP BY A.idtab, idatr
  ORDER BY 1, 3;

BEGIN

  i := 0;
  FOR c1 IN cr LOOP
    i := i + 10;
    UPDATE s_qatr
    SET num = i
    WHERE s_qatr.ID = C1.ID;
  END LOOP;

END;
$$ LANGUAGE plpgsql;

/* **************************************************** */
/*               РАБОТА С ИЗОБРАЖЕНИЯМИ                 */
/* **************************************************** */

---------------------------------------
--Складывает два пути к файлам, выполняя проверку на символ ''
CREATE OR REPLACE FUNCTION kamis_mark.ADD_PATH(
  in_path1 VARCHAR(4000),
  path2 VARCHAR(4000)
)
RETURNS VARCHAR(4000) 
AS $$
DECLARE
  path1 VARCHAR(1000);
BEGIN
  path1 := in_path1;
  IF LENGTH(path2) = 0 THEN      
    RETURN path1;
  END IF;
  IF SUBSTR( path1, LENGTH(path1) ) = '' AND SUBSTR( path2, 1, 1 ) = '' THEN      
    RETURN SUBSTR( path1, LENGTH(path1-1) )||path2;
  ELSIF SUBSTR( path1, LENGTH(path1) ) = '' OR SUBSTR( path2, 1, 1 ) = '' THEN      
    RETURN path1||path2;
  ELSE      
    RETURN path1||''||path2;
  END IF;
END;
$$ LANGUAGE plpgsql;

---------------------------------------
-- 27.08.2018 YL Перенесено в DB_UTIL. Здесь  оставлено для обратной совместимости c Forms, убрано rotation

-- Возврашает имя файла, связанного с нужной записью
-- в файле MEDIA
-- Parameters:
--      idl - ID_BAS в MEDIA
--      ret_pyr:
--              0 - возврашает само изображение
--              1 - в случае, если есть пирамида,
--              возврашает пирамиду. Для печати или
--              для I-net каталогов.
CREATE OR REPLACE FUNCTION kamis_mark.get_img_fn_by_id(
  id1 INTEGER, 
  ret_pyramid INTEGER = 0
) 
RETURNS VARCHAR(4000)
AS $$
DECLARE
  -- idl - код в таблице MEDIA
  fn VARCHAR(1000);
  filename VARCHAR(250);
  ext VARCHAR(250);
  server_id BIGINT;
  pyramida BIGINT;
  PATH VARCHAR(250);
  v_rotation INT;
BEGIN

  IF id1 IS NULL THEN
    RETURN NULL;
  END IF;
  SELECT
    media.filename,
    media.ext,
    media.server_id,
    media.pyramida,
    s.PATH
  INTO filename, ext, server_id, pyramida, PATH
  FROM
    media media,
    s_img_server S
  WHERE
    media.server_id = S.ID AND media.id_bas = id1;

  IF pyramida>0 AND ret_pyramid = 1 THEN
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
      FROM med_med A, media media, s_img_server S
      WHERE
        media.server_id = S.ID AND media.id_bas = A.medcode AND
        A.medcode2 = id1 AND
        media.status = 2;
      EXCEPTION WHEN NO_DATA_FOUND THEN
      NULL;
    END;
  END IF;

  IF pyramida>0 THEN
    ext := 'ac001001.spf';
    IF v_rotation IS NOT NULL THEN
      ext := ext||'?rotation = '||v_rotation;
    END IF;
  END IF;

  fn := ADD_PATH( PATH, filename)||ext;

  RETURN fn;
  EXCEPTION
  WHEN OTHERS THEN

RETURN NULL;
END;
$$ LANGUAGE plpgsql;


---------------------------------------
--Проверка использования данного изображения
CREATE OR REPLACE FUNCTION kamis_mark.MED_IS_USED (
  tecmed INTEGER
)
RETURNS INTEGER
AS $$
DECLARE
--tecmed - текущий код файла MEDIA
--возврашает: 0 - нигде не используется
--         НЕ 0 - есть ссылки на данный объект
  cou INTEGER;
  sql_comm VARCHAR(1000);

BEGIN

  cou := 0;
  FOR cc1 IN (SELECT DISTINCT idatr, idtab FROM s_qatr WHERE id_tab_r = 'MEDIA') LOOP
    sql_comm := 'SELECT COUNT(*) FROM '||cc1.idtab||' WHERE '||cc1.idatr||' = '||tecmed;
    cou := UTILS.Select_Value( sql_comm );
    IF cou!= 0 THEN
      EXIT;
    END IF;
  END LOOP;
  
RETURN cou;
END MED_IS_USED;
$$ LANGUAGE plpgsql;

-----------------------------------------------
-- Замена одного изображения в БД на другое
-- по всем файлам связкам
CREATE OR REPLACE FUNCTION kamis_mark.REPLACE_IMG(
  medcode INT,
  new_medcode INT
)
RETURNS VOID
AS $$
DECLARE
  sql_comm VARCHAR(1000);
BEGIN
  -- Второй проход - замена данных
  FOR cc1 IN (SELECT DISTINCT idatr, idtab FROM s_qatr WHERE id_tab_r = 'MEDIA') LOOP
    sql_comm := 'UPDATE '||cc1.idtab||' SET '||cc1.idatr||' = '||new_medcode||' WHERE '||cc1.idatr||' = '||medcode;
    EXECUTE sql_comm;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------
-- Для заданного изображения в файле MEDIA возвращает связанное с ним
-- изображенитакогое со статусом 1. Или его самого (если у него status и так 1)
-- Если  изображения нет возврашает NULL
-- -----------------------------------------------------------------
CREATE OR REPLACE FUNCTION kamis_mark.FIND_MAIN_IMG(
  p_medcode  INT,
  p_kversion INT = 2000 -- версия КАМИС: 2000 - KAMIS2000, 5 - KAMIS5
) 
RETURNS NUMERIC
AS $$
DECLARE
  my_status NUMERIC;
  my_medcode NUMERIC;
  v_kversion number;
BEGIN
  v_kversion := COALESCE (p_kversion, 2000);
  IF p_medcode<1 THEN -- Некоректный код
    RETURN p_medcode;
  END IF;
  SELECT status
  INTO my_status
  FROM media
  WHERE id_bas = p_medcode;
    IF my_status = 1 OR (my_status = 3 AND v_kversion = 2000) THEN

    RETURN p_medcode;
  END IF;
  BEGIN
    IF p_kversion = 5
    THEN
      SELECT A.medcode2
      INTO my_medcode
      FROM med_med A, media b
      WHERE A.medcode = p_medcode AND A.medcode2 = b.id_bas AND b.status = 1;
    ELSE
      SELECT A.medcode
      INTO my_medcode
      FROM med_med A, media b
      WHERE A.medcode2 = p_medcode AND A.medcode = b.id_bas AND b.status = 1;
    END IF;

    EXCEPTION WHEN OTHERS THEN

    RETURN NULL;
  END;

RETURN my_medcode;
END FIND_MAIN_IMG;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------
-- Меняет status у изображения
-- Делает главным (со статусом 1 изображение new_main_medcode)
-- Дополнительно создает связку в med_med
-- new_main_medcode  <---> p_medcode
-- ПОКА РАБОТАЕТ В ОТДЕЛЬНОЙ ТРАНЗАКЦИИ
-- НЕ работает в отдельной транзакции (так-как возможны конфликты с Forms'ом
-- именно в этой ф-ции, можно напороться на записи, которые были заблокированны
-- нами-же)

CREATE OR REPLACE FUNCTION kamis_mark.CHANGE_IMG_STATUS(
  p_medcode INT,
  new_status INT,
  new_main_medcode INT
)
RETURNS VOID
AS $$
-- DECLARE
--   PRAGMA autonomous_transaction;
BEGIN

  IF p_medcode>0 THEN
     REPLACE_IMG( p_medcode, new_main_medcode );
     UPDATE media SET status = new_status WHERE id_bas = p_medcode;
     INSERT INTO med_med (ID, medcode, medcode2) VALUES ( nextval('SEQ_S'), new_main_medcode, p_medcode );
     /* COMMIT; */
  END IF;
END;
$$ LANGUAGE plpgsql;

/*

FUNCTION kamis_mark.get_img_fn_by_paicode( p_paicode number, only_name number ) 
RETURNS VARCHAR
AS $$
DECLARE
  typimg1 NUMERIC;
  my_medcode NUMERIC;
  my_name varchar(1000);
BEGIN
  my_name := '';
  BEGIN
    SELECT MIN(id_bas) INTO typimg1 FROM KLASS WHERE ID_KL = 5;
    IF only_name = 1 THEN
       SELECT media.filename||media.ext INTO my_name
       FROM PAI_MED, MEDIA
       WHERE paicode = p_paicode AND typimg = typimg1 AND medcode = id_bas;
       
RETURN my_name;
    ELSE
       SELECT medcode INTO my_medcode
       FROM PAI_MED
       WHERE paicode = p_paicode AND typimg = typimg1;
       
RETURN get_img_fn_by_id( my_medcode );
    END IF;
  EXCEPTION WHEN OTHERS THEN
    
RETURN NULL;
  END;
END;
$$ LANGUAGE plpgsql;
*/

CREATE OR REPLACE FUNCTION kamis_mark.get_img_fn_by_paicode(
  p_paicode INT,
  only_name INT = 0
)
RETURNS VARCHAR(4000)
AS $$
DECLARE
  typimg1 INT;
  my_medcode INT;
  my_name VARCHAR(1000);
  my_pyramida INT;

BEGIN

  my_name := '';
  BEGIN
    SELECT MIN(id_bas)
    INTO typimg1
    FROM KLASS
    WHERE ID_KL = 5;
    SELECT
      media.id_bas,
      media.pyramida
    INTO my_medcode, my_pyramida
    FROM pai_med, media
    WHERE pai_med.paicode = p_paicode AND pai_med.typimg = typimg1 AND pai_med.medcode = media.id_bas;
    IF my_pyramida = 1 THEN
      NULL;
    ELSE
      BEGIN
        SELECT c.id_bas
        INTO my_medcode
        FROM media A, med_med b, media c
        WHERE A.id_bas = my_medcode AND A.id_bas = b.medcode AND b.medcode2 = c.id_bas AND c.status = 2;
        EXCEPTION WHEN NO_DATA_FOUND THEN
        NULL;
      END;
    END IF;

    IF only_name = 1 THEN
      SELECT media.filename || media.ext
      INTO my_name
      FROM MEDIA
      WHERE id_bas = my_medcode;

      RETURN my_name;
    ELSE

      RETURN get_img_fn_by_id( my_medcode );
    END IF;
    EXCEPTION WHEN OTHERS THEN

    RETURN NULL;
  END;
END;
$$ LANGUAGE plpgsql;

-- Возврашает:
-- 0 - нет ошибок
-- 1 - ошибки
-- Работает в отдельной транзакции
CREATE OR REPLACE FUNCTION kamis_mark.Add_Record_To_Media(
  p_id_bas INT,
  p_source_file VARCHAR(4000),
  p_name VARCHAR(4000),
  p_filename VARCHAR(4000),
  p_ext VARCHAR(4000),
  p_pyramida INT,
  p_filesize INT,
  p_filecsum INT,
  p_server_id VARCHAR(4000),
  p_status INT,
  p_img VARCHAR(4000),          -- In HEX format
  names TSmalStrs,             -- Название и значения переменных для Bind'инга
  TYPES TSmalStrs,             -- 'v', 'd', 'n'
  vals TLargeStrs,
  prev_medcode INT      -- Ссылка на Главное изображение
)
RETURNS VARCHAR(4000)
AS $$
DECLARE
  raw_buffer BYTEA; -- (32766);
  sql_comm VARCHAR(2000);
  fields_list VARCHAR(4000);
  i INT;
--   res INT;
  v_h_server int;
BEGIN

  raw_buffer := HEXTORAW(p_img); -- custom function HEXTORAW - see above
  BEGIN
       EXECUTE 'select h_server from s_img_server where id = $1' INTO v_h_server USING p_server_id;
       EXCEPTION WHEN OTHERS THEN NULL;
  END;
  LOCK TABLE media IN EXCLUSIVE MODE;
  EXECUTE 'INSERT INTO media
      (id_bas, source_file, NAME,
      filename, ext, pyramida,
      filesize, filecsum, server_id, status,
      filecdate,
      img, h_server)
      VALUES
      ($1, $2, $3,
      $4, $5, $6,
      $7, $8, $9, $10,
      SYSDATE,
      $11, $12)'
     USING
      p_id_bas, p_source_file, p_name,
      p_filename, p_ext, p_pyramida,
      p_filesize, p_filecsum, p_server_id, p_status,
      raw_buffer, v_h_server;

/*
    INSERT INTO media
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
      raw_buffer );
*/
  IF names IS NOT NULL AND names.COUNT > 0 THEN
/*
    IF names.count!= vals.count THEN
      ROLLBACK;
      
RETURN 'Field names and values lists has other length.';
    END IF;
*/

    -- Требуется запись дополнительных полей, придется работать через DBMS_SQL
    -- Создаем список дополнительных полей для вставки
    fields_list := NULL;

    FOR i IN array_lower(names, 1) .. array_upper(names, 1) LOOP

      IF vals.EXISTS(i) AND vals(i) IS NOT NULL THEN
        IF TYPES(i) IN ('c','v') THEN
          fields_list := names(i)||' = $1';
        ELSIF TYPES(i) IN ('n') THEN
          fields_list := names(i)||' = TO_NUMBER($1)';--orafce TO_NUMBER
        ELSIF TYPES(i) IN ('d') THEN
          fields_list := names(i)||' = TO_DATE($1,''DD.MM.YYYY'')';--orafce TO_DATE
        ELSIF TYPES(i) IN ('dt') THEN
          fields_list := names(i)||' = TO_DATE($1,''DD.MM.YYYY HH24:MI:SS'')';
        END IF;
      ELSE
        fields_list := names(i)||' = NULL';
      END IF;

      -- Создание SQL-команды
      sql_comm := 'UPDATE media SET '||fields_list||' WHERE id_bas = '||p_id_bas;  -- , :img

      -- Execute
      BEGIN
           /*
             Выполнение запроса может выбросить исключение из-за неправильного преобразования плавающих чисел.
             Это зависит от настроек десятичного разделителя.
             На данный момент просто отлавливаем ошибку и блокируем её.
             Added by mac, 25.04.2009
           */
--           res := DBMS_SQL.EXECUTE( cur );
          EXECUTE sql_comm USING vals(i);
      EXCEPTION WHEN OTHERS THEN
        NULL;
      END;

    END LOOP; -- i iterator over names,vals

  END IF; -- IF names IS NOT NULL AND names.COUNT > 0

  IF prev_medcode IS NOT NULL THEN
    INSERT INTO med_med ( ID, medcode, medcode2 ) VALUES ( nextval('seq_s'), prev_medcode, p_id_bas );
  END IF;
  RETURN NULL;

EXCEPTION WHEN OTHERS THEN
  RETURN DBMS_UTILITY.FORMAT_ERROR_STACK || ' ' ||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
         ||' p_filename, p_ext = '||p_filename||'/'||p_ext; -- orafce DBMS_UTILITY replacement exists - see https://pgxn.org/dist/orafce/doc/orafce_documentation/Orafce_Documentation_06.html
END Add_Record_To_Media;
$$ LANGUAGE plpgsql;

-- Ф-ция копирует одну запись с нужным типом и ID_BAS, таблица
-- определяется по tipo
-- ignory_table - таблица, связи с которой игнорируются,
--   например, если копирование выполняется для целей
--   дублирования карточек для добавления изображений,
--   копировать связи с MEDIA смысла нет, тогда, здесь
--   указывается ignory_table = 'MEDIA'
-- ВОЗВРАШАЕТ: номер новой записи
-- P.S. НЕ использует пометку kart_copy в KART'е
CREATE OR REPLACE FUNCTION kamis_mark.CopyRecord(
  p_tipo         INT,
  p_id_bas       INT,
  p_ignory_table VARCHAR(4000)
)
RETURNS INT
AS $$
DECLARE
  maintab VARCHAR(100);
  sql_comm1 VARCHAR(32767);
  sql_comm2 VARCHAR(32767);
  first_rec BOOLEAN;
  new_id_bas INT;
  BUFFER_STR VARCHAR(32767);

BEGIN

  /* Определяем, какая таблица для данного типа - 'главная' */
  SELECT UPPER(idtab)
  INTO maintab
  FROM kltipo
  WHERE id_bas = p_tipo;
  ---
  /* Цикл по всем полям, которые лежат в главной таблице */
  IF maintab = 'PAINTS'
  THEN
    SELECT nextval('SEC_PAINTS')
    INTO new_id_bas
    FROM dual;
  ELSE
    SELECT nextval('SEQ_KA')
    INTO new_id_bas
    FROM dual;
  END IF;
  ---
  sql_comm1 := 'INSERT INTO '||maintab||' ( id_bas';
  sql_comm2 := ' ) SELECT '||new_id_bas||' AS id_bas';
  ---
  -- Таким образом нельзя переносить поля типов:
  -- BIGINT, TEXT, BYTEA
  FOR C IN ( SELECT *
    FROM sys_all_tab_columns
    WHERE table_name = maintab
    AND column_name != 'ID_BAS'
    AND data_type NOT IN ('BIGINT', 'TEXT', 'BYTEA') )
  LOOP
    sql_comm1 := sql_comm1||', '|| C.column_name;
    sql_comm2 := sql_comm2||', '|| C.column_name;
  END LOOP;
  ---
  sql_comm1 := sql_comm1||sql_comm2||' FROM '||maintab||' WHERE id_bas = '||p_id_bas;
  --DBMS_OUTPUT.PUT_LINE(sql_comm1);
  EXECUTE sql_comm1;
  ---
  -- Доносим поля BIGINT   (TEXT, BYTEA-так просто не перенесем)
  FOR C IN ( SELECT *
    FROM sys_all_tab_columns
    WHERE table_name = maintab
    AND column_name != 'ID_BAS'
    AND data_type IN ('BIGINT') )
  LOOP
    ---
    BUFFER_STR := NULL;
    ---
    BEGIN
      sql_comm1 := 'SELECT '|| C.column_name||' FROM '||maintab || ' WHERE id_bas = ' || p_id_bas;
      --DBMS_OUTPUT.PUT_LINE(sql_comm1);
      EXECUTE sql_comm1 INTO BUFFER_STR;
      EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
      BUFFER_STR := NULL;
    END;
    ---
    IF BUFFER_STR IS NOT NULL
    THEN
      sql_comm1 := 'UPDATE '||maintab||' SET '|| quote_literal(C.column_name)||' = ?  WHERE id_bas = '||new_id_bas;
      --DBMS_OUTPUT.PUT_LINE(sql_comm1);
      EXECUTE sql_comm1 USING IN BUFFER_STR;
    END IF;
    ---
  END LOOP;
  ---
  -- Цикл по всем полям, которые лежат в таблицах связках
  -- кроме таблиц, связывающих с ignory_table
  -- Поля, хранящиеся в связках берутся из KART'ы, а информация
  -- о таблицах связках из all_tab_columns
  FOR c1 IN ( SELECT DISTINCT UPPER(idtab) idtab, id_sv2
  FROM kart
  WHERE tipo       = p_tipo
    AND idtab       != maintab
    AND UPPER(idfr) != 'ID_BAS'
    AND id_sv2 IS NOT NULL
    AND idtab NOT IN
    ( SELECT DISTINCT idtab
      FROM s_qatr
      WHERE s_qatr.id_tab_r = p_ignory_table )
    AND idtab IN ( SELECT table_name FROM sys_all_tab_columns)
  )
  LOOP
    sql_comm1 := 'INSERT INTO '||c1.idtab||' ( id';
    sql_comm2 := ' ) SELECT nextval(''SEQ_S'')';

    /* Цикл по всем физическим полям, в таблицах связки */
    FOR c2 IN (
      SELECT *
      FROM sys_all_tab_columns
      WHERE table_name = UPPER(c1.idtab)
        AND column_name != 'ID'
        AND data_type NOT IN ('BIGINT', 'TEXT', 'BYTEA')
    )
    LOOP
      sql_comm1 := sql_comm1||', '||c2.column_name;
      IF c2.column_name = c1.id_sv2
      THEN
        sql_comm2 := sql_comm2||', '||new_id_bas||' AS '||c2.column_name;
      ELSE
        sql_comm2 := sql_comm2||', '||c2.column_name;
      END IF;
    END LOOP;
    ---
    sql_comm2 := sql_comm2||' FROM '||c1.idtab||' WHERE '||c1.id_sv2||' = '||p_id_bas;
    ---
    --    IF c1.usl_we is not null THEN
    --      sql_comm2 := sql_comm2||' AND '||c1.usl_we;
    --    END IF;
    --    IF c1.attr_func is not null THEN
    --      sql_comm2 := sql_comm2||' AND attr_func = '||c1.attr_func;
    --    END IF;
    ---
    sql_comm1 := sql_comm1||sql_comm2;
    --DBMS_OUTPUT.PUT_LINE(sql_comm1);
    EXECUTE sql_comm1;
  END LOOP;
  ---

  RETURN new_id_bas;
  ---
END CopyRecord;
$$ LANGUAGE plpgsql;

------------------------------------------
-- Возврашает максимальный уровень пирамиды,
-- расчет основывается на размере исходного файла
CREATE OR REPLACE FUNCTION kamis_mark.GetLevelsCount(
  width PLS_INTEGER,
  height PLS_INTEGER
)
RETURNS PLS_INTEGER
AS $$
DECLARE
  mdx CONSTANT NUMERIC := 720;
  mdy CONSTANT NUMERIC := 576;
  R1 NUMERIC;
  R2 NUMERIC;
  R NUMERIC;
  LEVELS PLS_INTEGER;
BEGIN
  R1 := width / mdx;
  R2 := height/mdy;
  IF R1>R2 THEN
    R := R1;
  ELSE
    R := R2;
  END IF;

  IF R>1 THEN
    LEVELS := 4;
    WHILE R>3 LOOP
      LEVELS := LEVELS+1;
      R := R/2;
    END LOOP;
  ELSE
    LEVELS := 3;
    WHILE R<1 AND LEVELS>1 LOOP
      LEVELS := LEVELS-1;
      R := R*2;
    END LOOP;
  END IF;

  RETURN LEVELS;
END;
$$ LANGUAGE plpgsql;

-- Возврашают ошибки состояния файла S_FILES
-- системы обновления
-- Если данная ф-ция вернула пустой курсор - значит состояние на
-- сервере Скомпилировано
CREATE OR REPLACE FUNCTION kamis_mark.GetCompileError(
  c IN OUT CCOMPILEERR_REF
)
RETURNS VOID
AS $$
BEGIN
  OPEN c FOR
  -- Нет скомпилированных версий
  SELECT
    fname,
    ftype,
    xname,
    fdate,
    'Нет скомпилированной версии' AS err
  FROM s_files A
  WHERE (A.auto_compile = 1 OR A.auto_generate = 1) AND A.xname IS NOT NULL AND
        NOT EXISTS(SELECT *
                   FROM s_files b
                   WHERE b.fname = A.xname)
  -- Нет Upload'ых данных
  UNION
  SELECT
    fname,
    ftype,
    xname,
    fdate,
    'Нет данных' AS err
  FROM s_files A
  WHERE (ftype != 'DIR' OR ftype IS NULL) AND (fdate IS NULL OR bin IS NULL OR fsize < 1)
  -- Нет настроечных файлов для создания форм (для FMB, для MMB - их и быть не должно)
  UNION
  SELECT
    fname,
    ftype,
    xname,
    fdate,
    'Нет настроечных файлов для форм' AS err
  FROM s_files A
  WHERE auto_generate = 1 AND ftype = 'FMB' AND (bin2 IS NULL OR fname2 IS NULL)
  -- Модули, имеющие ошибки времени компиляции
  UNION
  SELECT
    fname,
    ftype,
    xname,
    fdate,
    'Неверное время скомпилированного файла' AS Err
  FROM S_FILES
  WHERE xname IS NOT NULL AND (auto_compile = 1 OR auto_generate = 1) AND
        fdate > (
          SELECT MIN(A.fdate)
          FROM S_FILES A
          WHERE EXISTS(SELECT xname
                       FROM S_FILES
                       WHERE xname = A.fname
                             AND (auto_compile = 1 OR auto_generate = 1))
        );
END;
$$ LANGUAGE plpgsql;

------------------------------------------------
-- Возврашает истинну - если в таблицы S_FILES
-- лежат корректно скомпилированные библиотеки
-- для всех исходных файлов (кроме создаваемых
-- автоматически PAINTS.FMB, ARTIST.FMB и т.д.)
CREATE OR REPLACE FUNCTION kamis_mark.FilesInDbIsGood 
RETURNS BOOLEAN
AS $$
DECLARE
  c1 cCompileErr_ref;
  rec cCompileErr_rec;
  flag BOOLEAN;

BEGIN

  GetCompileError( c1 );
  FETCH c1 INTO rec;
    IF c1%NOTFOUND THEN
      flag := TRUE; -- Нет ошибок
    ELSE
      flag := FALSE; -- Ошибка
    END IF;
  CLOSE c1;

  RETURN flag;
END FilesInDbIsGood;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION kamis_mark.GetImgFile(
  p_id_bas INT,
  with_path_flag INT = 0
)
RETURNS VARCHAR
AS $$
DECLARE
  my_filename varchar(1000);
  my_pyramida NUMERIC(10);
  my_server_id NUMERIC(10);
  my_serverpath varchar(1000);
BEGIN
  SELECT filename||ext, pyramida, server_id  INTO my_filename,my_pyramida, my_server_id  FROM media WHERE id_bas = p_id_bas;
  IF my_pyramida = 1 THEN
    RETURN '';
  END IF;
  IF with_path_flag = 1 THEN
    SELECT PATH INTO my_serverpath FROM s_img_server WHERE ID = my_server_id;
    my_filename := my_serverpath||''||my_filename;
  END IF;
  
  RETURN my_filename;
    EXCEPTION WHEN OTHERS THEN

  RETURN '';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION kamis_mark.GetPyrFile(
  p_id_bas INT,
  with_path_flag INT = 0
)
RETURNS VARCHAR
AS $$
DECLARE
  my_filename varchar(1000);
  my_pyramida NUMERIC;
  my_server_id NUMERIC(10);
  my_serverpath varchar(1000);
BEGIN
  SELECT filename, pyramida, server_id INTO my_filename, my_pyramida, my_server_id FROM media WHERE id_bas = p_id_bas;
  IF my_pyramida = 1 THEN
    NULL;
  ELSE
    BEGIN
      SELECT c.filename, c.pyramida, c.server_id
        INTO my_filename, my_pyramida, my_server_id
        FROM media A, med_med b, media c
        WHERE A.id_bas = p_id_bas AND A.id_bas = b.medcode AND b.medcode2 = c.id_bas AND c.status = 2;
    EXCEPTION WHEN NO_DATA_FOUND THEN

    RETURN '';
    END;
  END IF;
  IF with_path_flag = 1 THEN
    SELECT PATH INTO my_serverpath FROM s_img_server WHERE ID = my_server_id;
    my_filename := my_serverpath||''||my_filename;
  END IF;
  
  RETURN my_filename;
  EXCEPTION WHEN OTHERS THEN

RETURN '';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION kamis_mark.Test 
RETURNS VOID
AS $$
BEGIN
NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION kamis_mark.Test_Out(
  A IN OUT INT
)
RETURNS VOID
AS $$
BEGIN
 A := A * A;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION kamis_mark.Test_Add(
  A INT,
  b INT
)
RETURNS INT
AS $$
BEGIN
  RETURN A+b;
END;
$$ LANGUAGE plpgsql;

-- Преобразует строчку в корректное имя файла. Заменяет символы
-- :/ на тире и символы *?_ на пробел
CREATE OR REPLACE FUNCTION kamis_mark.CorrectFileName(
  s VARCHAR(4000)
)
RETURNS VARCHAR(4000)
AS $$
DECLARE
  fn VARCHAR(200);

BEGIN

  fn := RTRIM( LTRIM( SUBSTRB( S, 1, 200 ) ) );
  fn := REPLACE ( fn, ':', '-' );
  fn := REPLACE ( fn, '', '-' );
  fn := REPLACE ( fn, '/', '-' );
  fn := REPLACE ( fn, '*', ' ' );
  fn := REPLACE ( fn, '?', ' ' );
  fn := REPLACE ( fn, '_', ' ' );
  fn := REPLACE ( fn, '.', ' ' );
  fn := REPLACE ( fn, '"', ' ' );
  IF fn IS NULL THEN
    fn := 'noname';
  END IF;
  
  RETURN fn;
END CorrectFileName;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION kamis_mark.TrimSpecChars(
  param VARCHAR(4000)
)
RETURNS VARCHAR(4000)
AS $$
DECLARE
  s VARCHAR(32000);
  c VARCHAR(10);
  pos PLS_INTEGER;

BEGIN
  s := param;
  pos := LENGTH(s);
  WHILE pos > 0 LOOP
    c := SUBSTR( s, pos, 1 );
    IF c NOT IN ( CHR(32), CHR(9), CHR(10), CHR(13) ) THEN      
      RETURN SUBSTR( s, 1, pos );
    END IF;
    pos := pos-1;
  END LOOP;

  RETURN '';
END TrimSpecChars;
$$ LANGUAGE plpgsql;


/*
  Ф-ции добавляют и изменяют данные в записи
  'Текст' в таблицы UTF8.
  Данная запись используется для передачи информации между
  формой UTF8 и KAMIS'ом.

  Note: Алгоритм передачи был сделан Еленой Львовной
  Кощеевой.
*/
CREATE OR REPLACE FUNCTION kamis_mark.GetUtf8Text(
  ID VARCHAR(4000)
)
RETURNS VARCHAR(4000)
AS $$
DECLARE
  res VARCHAR(32767);

BEGIN
  EXECUTE 'SELECT TEXT_V FROM T_UTF8 WHERE ID = $1'
  INTO res USING ID;

  RETURN res;
END GetUtf8Text;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION kamis_mark.SetUtf8Text(
  ID VARCHAR(4000),
  s VARCHAR(4000)
)
RETURNS VOID
AS $$
BEGIN
  EXECUTE 'UPDATE T_UTF8 SET TEXT_V = $1 WHERE ID = $2'
  USING S, ID;
END;
$$ LANGUAGE plpgsql;
