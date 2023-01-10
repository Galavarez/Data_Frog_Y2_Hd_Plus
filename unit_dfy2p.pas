unit unit_dfy2p;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ShellAPI, Zipper;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button_Build_ZES: TButton;
    Button_Path_PNG: TButton;
    Button_Path_NES: TButton;
    Button_Save_PNG_from_ZES: TButton;
    Button_Resset_All: TButton;
    Edit_Name_Game: TEdit;
    Edit_Path_PNG: TEdit;
    Edit_Path_NES: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    Image1: TImage;
    OpenDialog_ZES: TOpenDialog;
    OpenDialog_Path_NES: TOpenDialog;
    OpenDialog_Path_PNG: TOpenDialog;
    procedure Button_Build_ZESClick(Sender: TObject);
    procedure Button_Path_NESClick(Sender: TObject);
    procedure Button_Path_PNGClick(Sender: TObject);
    procedure Button_Save_PNG_from_ZESClick(Sender: TObject);
    procedure Button_Resset_AllClick(Sender: TObject);
  private
    procedure Get_NAME;
    procedure Get_PNG;
    procedure Get_ZIP_from_NES;

  public

  end;

var
  Form1: TForm1;
  // ZIP
  PATH_ZIP_GLOBAL: String;
  SIZE_ZIP_IN_HEX_GLOBAL: String;
  // PNG
  PATH_PNG_GLOBAL: String;
  SIZE_PNG_IN_HEX_GLOBAL: String;
  // Name
  NAME_GAME : String;
  LEANGTH_NAME_GAME: SizeInt;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Get_ZIP_from_NES();
var
  ZIP: TZipper;
  LANGTH_NAME_LOCAL: SizeInt;
  NAME_NES_FOR_ZIP: String;
  ZIP_FILE : File of Byte;
begin
     // Получаем имя без пути
     NAME_NES_FOR_ZIP := ExtractFileName(Edit_Path_NES.Text);
     // Получаем длину символов
     LANGTH_NAME_LOCAL := Length(NAME_NES_FOR_ZIP);
     // Удаляем расширение файла .nes
     Delete(NAME_NES_FOR_ZIP, LANGTH_NAME_LOCAL - 3, 4);
     // Вставляем расширение .zip
     Insert('.zip', NAME_NES_FOR_ZIP, LANGTH_NAME_LOCAL);
     // name_zip := StringReplace(name_zes, '.nes', '.zip', [rfReplaceAll, rfIgnoreCase]);
     // Переменная для ZIP архива
    ZIP := TZipper.Create;
    try
      // Имя с расширением .zip
      ZIP.FileName:= NAME_NES_FOR_ZIP;
      // Добавляем NES в ZIP архив
      ZIP.Entries.AddFileEntry(Edit_Path_NES.Text, ExtractFileName(Edit_Path_NES.Text));
      // Сохраняем ZIP архив
      ZIP.ZipAllFiles;
    finally
      // Очищаем память
      FreeAndNil(ZIP)
    end;
    // Сохраняем путь к ZIP архиву
    PATH_ZIP_GLOBAL := ExtractFilePath(paramstr(0) + NAME_NES_FOR_ZIP) + NAME_NES_FOR_ZIP;
    // Открываем файл
    AssignFile(ZIP_FILE, PATH_ZIP_GLOBAL);
    // для чтения
    Reset(ZIP_FILE);
    // Получаем размер ZIP в HEX виде
    SIZE_ZIP_IN_HEX_GLOBAL := IntToHex( FileSize(ZIP_FILE), 8);
    // Закрываем файл
    CloseFile(ZIP_FILE);
end;

procedure TForm1.Get_PNG();
var
  png : File of Byte;
begin
  PATH_PNG_GLOBAL := Edit_Path_PNG.Text;
  AssignFile(png, Edit_Path_PNG.Text);
  Reset(png);
  SIZE_PNG_IN_HEX_GLOBAL := IntToHex(FileSize(png), 8);
  CloseFile(png);
end;

procedure TForm1.Get_NAME();
begin
  NAME_GAME := ExtractFileName(Edit_Name_Game.Text);
  LEANGTH_NAME_GAME := Length(NAME_GAME);
end;

procedure TForm1.Button_Build_ZESClick(Sender: TObject);
var
  head : Array[0..519] of Byte;
  a, b: Integer;
  HEADER : File of Byte;
  command: String;
begin
  // Получаем Name
  Get_NAME;

  // Создаем заголовок в 512 байт
  for a:=0 to 511 do
  begin
    if LEANGTH_NAME_GAME > a then
    begin
         head[a] := Byte(NAME_GAME[a+1]);
    end
       else
    begin
         head[a] := Byte($00);
    end;
  end;

  // Получаем PNG
  Get_PNG;

  // Записываем размер PNG в HEADER
  head[512] := StrToInt('$' + SIZE_PNG_IN_HEX_GLOBAL[7] + SIZE_PNG_IN_HEX_GLOBAL[8]);
  head[513] := StrToInt('$' + SIZE_PNG_IN_HEX_GLOBAL[5] + SIZE_PNG_IN_HEX_GLOBAL[6]);
  head[514] := StrToInt('$' + SIZE_PNG_IN_HEX_GLOBAL[3] + SIZE_PNG_IN_HEX_GLOBAL[4]);
  head[515] := StrToInt('$' + SIZE_PNG_IN_HEX_GLOBAL[1] + SIZE_PNG_IN_HEX_GLOBAL[2]);

  // Получаем ZIP из NES
  Get_ZIP_from_NES;

  // Записываем размер ZIP в HEADER
  head[516] := StrToInt('$' + SIZE_ZIP_IN_HEX_GLOBAL[7] + SIZE_ZIP_IN_HEX_GLOBAL[8]);
  head[517] := StrToInt('$' + SIZE_ZIP_IN_HEX_GLOBAL[5] + SIZE_ZIP_IN_HEX_GLOBAL[6]);
  head[518] := StrToInt('$' + SIZE_ZIP_IN_HEX_GLOBAL[3] + SIZE_ZIP_IN_HEX_GLOBAL[4]);
  head[519] := StrToInt('$' + SIZE_ZIP_IN_HEX_GLOBAL[1] + SIZE_ZIP_IN_HEX_GLOBAL[2]);

  // Создаем файл HEADER
  AssignFile( HEADER, 'header') ;
  Rewrite(HEADER);
  for b:=0 to 519 do
  begin
       Write(HEADER, head[b]);
  end;
  CloseFile(HEADER);

  // Создаем ZES
  command := '/c copy /b "header" + "' + PATH_PNG_GLOBAL + '" + "' + PATH_ZIP_GLOBAL + '" "' + NAME_GAME + '.zes"';
  ShellExecute( 0, PChar('open'), PChar('cmd'), PChar(command), nil, 0);

  // Удаляем временные файлы
  Sleep(2000);
  DeleteFile('header');
  DeleteFile(ExtractFileName(PATH_ZIP_GLOBAL));

  //
  ShowMessage('ZES файл готов!');
end;

procedure TForm1.Button_Path_NESClick(Sender: TObject);
begin
  if OpenDialog_Path_NES.Execute then
  begin
       Edit_Path_NES.Text:= OpenDialog_Path_NES.FileName;
  end;
end;

procedure TForm1.Button_Path_PNGClick(Sender: TObject);
begin
  if OpenDialog_Path_PNG.Execute then
  begin
       Edit_Path_PNG.Text:= OpenDialog_Path_PNG.FileName;
  end;
end;

procedure TForm1.Button_Save_PNG_from_ZESClick(Sender: TObject);
var
  FS, FS2: TFileStream;
  size_png : LongInt;
  file_png : TByteArray;
  path_zes, name_zes , name_png : String;
begin
  if OpenDialog_ZES.Execute then
  begin
    path_zes := OpenDialog_ZES.FileName;
    name_zes := ExtractFileName(path_zes);
    name_png := StringReplace(name_zes, '.zes', '.png', [rfReplaceAll, rfIgnoreCase]);

    // Получаю размер png
    FS := TFileStream.Create(path_zes, fmOpenRead);
    FS.Position:= 512;
    FS.Read(size_png, 7);
    // Получаю массив байтов png
    FS.Position:= 520;
    FS.Read(file_png, size_png);
    FS.Free;
    // Сохраняю массив байтов png в файл
    FS2 := TFileStream.Create(name_png, fmCreate);
    FS2.Write(file_png, size_png);
    FS2.Free;
    ShowMessage('Превьюшка успешно добыта!');
  end;
end;

procedure TForm1.Button_Resset_AllClick(Sender: TObject);
begin
  Edit_Name_Game.Clear;
  Edit_Path_NES.Clear;
  Edit_Path_PNG.Clear;
end;


end.

