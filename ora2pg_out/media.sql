CREATE TABLE IF NOT EXISTS MEDIA
(
  id_bas                       NUMBER(10) not null constraint MEDIA$PK unique,
  id_kl                        NUMBER(10),
  img                          BYTEA,
  filename                     VARCHAR(250),
  ext                          VARCHAR(60),
  source_file                  VARCHAR(1000),
  filecdate                    TIMESTAMP(0),
  filemdate                    TIMESTAMP(0),
  filecsum                     NUMBER(10),
  filesize                     NUMBER(38),
  server_id                    VARCHAR(250),
  name                         VARCHAR(250),
  type                         NUMBER(10),
  pyramida                     NUMBER(10),
  status                       NUMBER(10),
  idkluch                      VARCHAR(2000),
  width                        NUMBER(10),
  height                       NUMBER(10),
  resolution                   NUMBER(20,10),
  eq_make                      VARCHAR(250),
  eq_model                     VARCHAR(250),
  d_date                       TIMESTAMP(0),
  d_time                       VARCHAR(50),
  exposure                     NUMBER(20,10),
  expo_prg                     NUMBER(10),
  fnumber                      NUMBER(20,10),
  focal                        NUMBER(20,10),
  iso_number                   NUMBER(20,10),
  flash                        NUMBER(10),
  exif                         NUMBER(10),
  hash_pyramida                NUMBER(10),
  allnames                     VARCHAR(1000),
  levels                       NUMBER(10),
  filesize2                    NUMBER(10),
  filemtime                    VARCHAR(50),
  cd_jpeg                      VARCHAR(100),
  cd_tiff                      VARCHAR(100),
  creat                        VARCHAR(100),
  pres                         VARCHAR(100),
  kluch                        VARCHAR(200),
  make_as_failing_image_client VARCHAR(250),
  make_as_failing_image_date   TIMESTAMP(0),
  file_hash_value_sha1         VARCHAR(128),
  exif_xml_data                TEXT,
  opis_e                       VARCHAR(500),
  pravoobl                     VARCHAR(500),
  namel                        VARCHAR(250),
  opis                         VARCHAR(500),
  external_url                 VARCHAR(100),
  url                          VARCHAR(60),
  metadata_xml_data            TEXT,
  mime_type                    VARCHAR(250),
  hash_value_of_source_file    VARCHAR(128),
  row_insert_module            VARCHAR(128),
  row_insert_datetime          TIMESTAMP(0),
  username                     VARCHAR(400),
  loginid                      VARCHAR(400),
  userserv                     VARCHAR(400),
  exposure_c                   VARCHAR(200),
  final_date_for_storage_file  TIMESTAMP(0),
  not_edit                     NUMBER(10),
  cleanup_status               VARCHAR(400),
  mass_media_date              TIMESTAMP(0),
  mass_media_time              VARCHAR(60),
  h_server                     NUMBER(10),
  rotation                     NUMBER(10)
) tablespace USERS;

-- Add comments to the columns
comment on column MEDIA.id_bas
  is 'ID_BAS (он же MEDCODE в связках) - первичный ключ таблицы MEDIA';
comment on column MEDIA.img
  is 'Изображение в виде иконки';
comment on column MEDIA.filename
  is 'Имя файла без пути и расширения';
comment on column MEDIA.ext
  is 'Расширение файла (вместе с точкой)';
comment on column MEDIA.source_file
  is 'Исходный файл с изображением';
comment on column MEDIA.filecdate
  is 'Время создания изображения';
comment on column MEDIA.filemdate
  is 'Дата исходного файла';
comment on column MEDIA.filecsum
  is 'Контрольная сумма файла';
comment on column MEDIA.filesize
  is 'Длина файла';
comment on column MEDIA.server_id
  is '"Сервер" для хранения изображений';
comment on column MEDIA.name
  is 'Название изображения (для человека)';
comment on column MEDIA.type
  is 'Тип хранимой информации';
comment on column MEDIA.pyramida
  is 'Пирамида (1) или НЕТ (0) (для изображений)';
comment on column MEDIA.status
  is 'Статус: (STATUS=1 + PYRAMIDA=0) = исх. изобр.; (STATUS=1 + PYRAMIDA=1) = конвертированная пирамида(без исх. изобр.); STATUS=2 =пирамида; STATUS=3 =аудио/видео; STATUS=4 = документы';
comment on column MEDIA.idkluch
  is 'Список ключевых слов';
comment on column MEDIA.width
  is 'Кол-во точек по X';
comment on column MEDIA.height
  is 'Кол-во точек по Y';
comment on column MEDIA.resolution
  is 'Разрешение';
comment on column MEDIA.eq_make
  is 'Производитель камеры';
comment on column MEDIA.eq_model
  is 'Модель камеры';
comment on column MEDIA.d_date
  is 'Дата сьемки';
comment on column MEDIA.d_time
  is 'Время сьемки';
comment on column MEDIA.exposure
  is 'Выдержка';
comment on column MEDIA.expo_prg
  is 'Программа';
comment on column MEDIA.fnumber
  is 'Диафрагма';
comment on column MEDIA.focal
  is 'Фокусное растояние';
comment on column MEDIA.iso_number
  is 'Чувствительность по ISO';
comment on column MEDIA.flash
  is 'Вспышка';
comment on column MEDIA.exif
  is 'Получено из Exif (1) или НЕТ (0)';
comment on column MEDIA.hash_pyramida
  is 'Имеет пирамиду';
comment on column MEDIA.allnames
  is 'Название изображения (для человека) (вероятно был вариант полное название, но там тоже что в NAME почти всегда).';
comment on column MEDIA.levels
  is 'Кол-во уровней в пирамиде';
comment on column MEDIA.filesize2
  is 'Размер файла';
comment on column MEDIA.filemtime
  is 'Время исходного файла';
comment on column MEDIA.cd_jpeg
  is 'Номер (название) CD-диска с JPEG';
comment on column MEDIA.cd_tiff
  is 'Номер (название) CD-диска с TIFF';
comment on column MEDIA.creat
  is 'Дата съемки';
comment on column MEDIA.pres
  is 'Режим съемки';
comment on column MEDIA.kluch
  is 'Список ключевых слов';
comment on column MEDIA.make_as_failing_image_client
  is 'Флаг-пометка об "отсутствии изображения": клиент, поставивший такую отметку.';
comment on column MEDIA.make_as_failing_image_date
  is 'Флаг-пометка об "отсутствии изображения": дата последнего проставления такой отметки.';
comment on column MEDIA.exif_xml_data
  is 'Данные XML с EXIF информацией о файле.';
comment on column MEDIA.metadata_xml_data
  is 'Данные XML с META информацией о файле.';
comment on column MEDIA.mime_type
  is 'MIME-заголовок (ТИП ФАЙЛА) для браузера';
comment on column MEDIA.hash_value_of_source_file
  is 'Данные SHA1 от исходного файла для пирамид.';
comment on column MEDIA.row_insert_module
  is '"Модуль", вставивший запись (служебное поле)';
comment on column MEDIA.row_insert_datetime
  is 'Дата-время вставки записи (служебное поле)';
comment on column MEDIA.userserv
  is 'Виртуальный сервер';

-- Create/Recreate indexes 
create index MEDIA_1148065 on MEDIA (FILESIZE, FILECSUM);
create index MEDIA_1148066 on MEDIA (ID_BAS, STATUS);
create index MEDIA_5531832974 on MEDIA (H_SERVER);
create index MEDIA_566644014 on MEDIA (SERVER_ID);
create index MEDIA_566649903 on MEDIA (FILE_HASH_VALUE_SHA1);

-- Create/Recreate primary, unique and foreign key constraints 
ALTER TABLE USERS.MEDIA ADD PRIMARY KEY (ID_BAS);
