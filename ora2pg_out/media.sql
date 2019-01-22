create table MEDIA
(
  id_bas                       NUMBER(10) not null,
  id_kl                        NUMBER(10),
  img                          LONG RAW,
  filename                     VARCHAR2(250),
  ext                          VARCHAR2(60),
  source_file                  VARCHAR2(1000),
  filecdate                    DATE,
  filemdate                    DATE,
  filecsum                     NUMBER(10),
  filesize                     NUMBER(38),
  server_id                    VARCHAR2(250),
  name                         VARCHAR2(250),
  type                         NUMBER(10),
  pyramida                     NUMBER(10),
  status                       NUMBER(10),
  idkluch                      VARCHAR2(2000),
  width                        NUMBER(10),
  height                       NUMBER(10),
  resolution                   NUMBER(20,10),
  eq_make                      VARCHAR2(250),
  eq_model                     VARCHAR2(250),
  d_date                       DATE,
  d_time                       VARCHAR2(50),
  exposure                     NUMBER(20,10),
  expo_prg                     NUMBER(10),
  fnumber                      NUMBER(20,10),
  focal                        NUMBER(20,10),
  iso_number                   NUMBER(20,10),
  flash                        NUMBER(10),
  exif                         NUMBER(10),
  hash_pyramida                NUMBER(10),
  allnames                     VARCHAR2(1000),
  levels                       NUMBER(10),
  filesize2                    NUMBER(10),
  filemtime                    VARCHAR2(50),
  cd_jpeg                      VARCHAR2(100),
  cd_tiff                      VARCHAR2(100),
  creat                        VARCHAR2(100),
  pres                         VARCHAR2(100),
  kluch                        VARCHAR2(200),
  make_as_failing_image_client VARCHAR2(250),
  make_as_failing_image_date   DATE,
  file_hash_value_sha1         VARCHAR2(128),
  exif_xml_data                CLOB,
  opis_e                       VARCHAR2(500),
  pravoobl                     VARCHAR2(500),
  namel                        VARCHAR2(250),
  opis                         VARCHAR2(500),
  external_url                 VARCHAR2(100),
  url                          VARCHAR2(60),
  metadata_xml_data            CLOB,
  mime_type                    VARCHAR2(250),
  hash_value_of_source_file    VARCHAR2(128),
  row_insert_module            VARCHAR2(128),
  row_insert_datetime          DATE,
  username                     VARCHAR2(400),
  loginid                      VARCHAR2(400),
  userserv                     VARCHAR2(400),
  exposure_c                   VARCHAR2(200),
  final_date_for_storage_file  DATE,
  not_edit                     NUMBER(10),
  cleanup_status               VARCHAR2(400),
  mass_media_date              DATE,
  mass_media_time              VARCHAR2(60),
  h_server                     NUMBER(10),
  rotation                     NUMBER(10)
)
tablespace USERS
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 64M
    next 1M
    minextents 1
    maxextents unlimited
  );
-- Add comments to the columns 
comment on column MEDIA.id_bas
  is 'ID_BAS (�� �� MEDCODE � �������) - ��������� ���� ������� MEDIA';
comment on column MEDIA.img
  is '����������� � ���� ������';
comment on column MEDIA.filename
  is '��� ����� ��� ���� � ����������';
comment on column MEDIA.ext
  is '���������� ����� (������ � ������)';
comment on column MEDIA.source_file
  is '�������� ���� � ������������';
comment on column MEDIA.filecdate
  is '����� �������� �����������';
comment on column MEDIA.filemdate
  is '���� ��������� �����';
comment on column MEDIA.filecsum
  is '����������� ����� �����';
comment on column MEDIA.filesize
  is '����� �����';
comment on column MEDIA.server_id
  is '"������" ��� �������� �����������';
comment on column MEDIA.name
  is '�������� ����������� (��� ��������)';
comment on column MEDIA.type
  is '��� �������� ����������';
comment on column MEDIA.pyramida
  is '�������� (1) ��� ��� (0) (��� �����������)';
comment on column MEDIA.status
  is '������: (STATUS=1 + PYRAMIDA=0) = ���. �����.; (STATUS=1 + PYRAMIDA=1) = ���������������� ��������(��� ���. �����.); STATUS=2 =��������; STATUS=3 =�����/�����; STATUS=4 = ���������';
comment on column MEDIA.idkluch
  is '������ �������� ����';
comment on column MEDIA.width
  is '���-�� ����� �� X';
comment on column MEDIA.height
  is '���-�� ����� �� Y';
comment on column MEDIA.resolution
  is '����������';
comment on column MEDIA.eq_make
  is '������������� ������';
comment on column MEDIA.eq_model
  is '������ ������';
comment on column MEDIA.d_date
  is '���� ������';
comment on column MEDIA.d_time
  is '����� ������';
comment on column MEDIA.exposure
  is '��������';
comment on column MEDIA.expo_prg
  is '���������';
comment on column MEDIA.fnumber
  is '���������';
comment on column MEDIA.focal
  is '�������� ���������';
comment on column MEDIA.iso_number
  is '���������������� �� ISO';
comment on column MEDIA.flash
  is '�������';
comment on column MEDIA.exif
  is '�������� �� Exif (1) ��� ��� (0)';
comment on column MEDIA.hash_pyramida
  is '����� ��������';
comment on column MEDIA.allnames
  is '�������� ����������� (��� ��������) (�������� ��� ������� ������ ��������, �� ��� ���� ��� � NAME ����� ������).';
comment on column MEDIA.levels
  is '���-�� ������� � ��������';
comment on column MEDIA.filesize2
  is '������ �����';
comment on column MEDIA.filemtime
  is '����� ��������� �����';
comment on column MEDIA.cd_jpeg
  is '����� (��������) CD-����� � JPEG';
comment on column MEDIA.cd_tiff
  is '����� (��������) CD-����� � TIFF';
comment on column MEDIA.creat
  is '���� ������';
comment on column MEDIA.pres
  is '����� ������';
comment on column MEDIA.kluch
  is '������ �������� ����';
comment on column MEDIA.make_as_failing_image_client
  is '����-������� �� "���������� �����������": ������, ����������� ����� �������.';
comment on column MEDIA.make_as_failing_image_date
  is '����-������� �� "���������� �����������": ���� ���������� ������������ ����� �������.';
comment on column MEDIA.exif_xml_data
  is '������ XML � EXIF ����������� � �����.';
comment on column MEDIA.metadata_xml_data
  is '������ XML � META ����������� � �����.';
comment on column MEDIA.mime_type
  is 'MIME-��������� (��� �����) ��� ��������';
comment on column MEDIA.hash_value_of_source_file
  is '������ SHA1 �� ��������� ����� ��� �������.';
comment on column MEDIA.row_insert_module
  is '"������", ���������� ������ (��������� ����)';
comment on column MEDIA.row_insert_datetime
  is '����-����� ������� ������ (��������� ����)';
comment on column MEDIA.userserv
  is '����������� ������';
-- Create/Recreate indexes 
create index MEDIA_1148065 on MEDIA (FILESIZE, FILECSUM)
  tablespace USERS
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );
create index MEDIA_1148066 on MEDIA (ID_BAS, STATUS)
  tablespace USERS
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );
create index MEDIA_5531832974 on MEDIA (H_SERVER)
  tablespace USERS
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );
create index MEDIA_566644014 on MEDIA (SERVER_ID)
  tablespace USERS
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );
create index MEDIA_566649903 on MEDIA (FILE_HASH_VALUE_SHA1)
  tablespace USERS
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );
-- Create/Recreate primary, unique and foreign key constraints 
alter table MEDIA
  add constraint MEDIA$PK primary key (ID_BAS)
  using index 
  tablespace USERS
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );
