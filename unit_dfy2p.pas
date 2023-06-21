unit unit_dfy2p;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls, Zipper, LCLIntf;

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
    Label_link_home: TLabel;
    OpenDialog_ZES: TOpenDialog;
    OpenDialog_Path_NES: TOpenDialog;
    OpenDialog_Path_PNG: TOpenDialog;
    procedure Button_Build_ZESClick(Sender: TObject);
    procedure Button_Path_NESClick(Sender: TObject);
    procedure Button_Path_PNGClick(Sender: TObject);
    procedure Button_Save_PNG_from_ZESClick(Sender: TObject);
    procedure Button_Resset_AllClick(Sender: TObject);
    procedure Label_link_homeClick(Sender: TObject);
  private
    procedure Get_ZIP_from_NES;

  public

  end;

var
  Form1: TForm1;
  // Потоки
  MemoryStream_ZIP : TMemoryStream;
  FileStream_PNG : TFileStream;
  MemoryStream_HEADER: TMemoryStream;
  FileStream_ZES : TFileStream;

implementation

{$R *.lfm}

{ TForm1 }

// Получаем ZIP из NES
procedure TForm1.Get_ZIP_from_NES();
var
  zip: TZipper;
  name_nes, name_zip: String;
begin
    // Получаем имя nes файла
    name_nes := ExtractFileName(Edit_Path_NES.Text);
    // Меняем расширение с nes на zip
    name_zip := StringReplace(name_nes, '.nes', '.zip', [rfReplaceAll, rfIgnoreCase]);
    // Создаем поток
    MemoryStream_ZIP := TMemoryStream.Create;
    // Создаем архив
    zip := TZipper.Create;
    try
      // Имя архива
      zip.FileName:= name_zip;
      // Добавляем NES в ZIP архив
      zip.Entries.AddFileEntry(Edit_Path_NES.Text, ExtractFileName(Edit_Path_NES.Text));
      // Сохраняем в поток
      zip.SaveToStream(MemoryStream_ZIP);
      // Сохраняем ZIP архив
      //zip.ZipAllFiles;
    finally
      // Очищаем память
      FreeAndNil(zip)
    end;

end;

procedure TForm1.Button_Build_ZESClick(Sender: TObject);
var
  array_header : Array[0..519] of Byte;
  i: Integer;
  name_game : String;
  length_name_game: SizeInt;
  // Переменные для перевода из Integer в Hex
  Int2Hex_size_png_int : Integer;
  Int2Hex_size_png_hex : TByteArray absolute Int2Hex_size_png_int;
  Int2Hex_size_zip_int : Integer;
  Int2Hex_size_zip_hex : TByteArray absolute Int2Hex_size_zip_int;
begin
  // Получаем Имя игры
  name_game := ExtractFileName(Edit_Name_Game.Text);
  // Получаем количество знаков в имени
  length_name_game := Length(name_game);

  // Создаем заголовок в 512 байт
  // Если есть буквы то записываем их иначе записываем нули
  for i := 0 to 511 do
  begin
    if length_name_game > i then
    begin
         array_header[i] := Byte(name_game[i + 1]);
    end
       else
    begin
         array_header[i] := Byte($00);
    end;
  end;

  // Получаем PNG в потоке
  FileStream_PNG := TFileStream.Create(Edit_Path_PNG.Text, fmOpenRead);

  // Получаем размер png
  Int2Hex_size_png_int := FileStream_PNG.Size;

  // Записываем размер PNG в HEADER
  array_header[512] := Int2Hex_size_png_hex[0];
  array_header[513] := Int2Hex_size_png_hex[1];
  array_header[514] := Int2Hex_size_png_hex[2];
  array_header[515] := Int2Hex_size_png_hex[3];

  // Получаем ZIP из NES
  Get_ZIP_from_NES;

  // Получаем размер ZIP архива
  Int2Hex_size_zip_int := MemoryStream_ZIP.Size;

  // Записываем размер ZIP в HEADER
  array_header[516] := Int2Hex_size_zip_hex[0];
  array_header[517] := Int2Hex_size_zip_hex[1];
  array_header[518] := Int2Hex_size_zip_hex[2];
  array_header[519] := Int2Hex_size_zip_hex[3];

  // Копируем массив заголовка в поток
  MemoryStream_HEADER := TMemoryStream.Create;
  MemoryStream_HEADER.Write(array_header, 520);

  // Создаем файл ZES
  FileStream_ZES := TFileStream.Create( name_game + '.zes', fmCreate);
  // Копируем поток HEADER
  MemoryStream_HEADER.Position := 0;
  FileStream_ZES.CopyFrom(MemoryStream_HEADER, MemoryStream_HEADER.Size);
  // Копируем поток PNG
  FileStream_PNG.Position := 0;
  FileStream_ZES.CopyFrom(FileStream_PNG, FileStream_PNG.Size);
  // Копируем поток ZIP
  MemoryStream_ZIP.Position := 0;
  FileStream_ZES.CopyFrom(MemoryStream_ZIP, MemoryStream_ZIP.Size);

  // Чистим память
  FileStream_ZES.Free;
  MemoryStream_HEADER.Free;
  FileStream_PNG.Free;
  MemoryStream_ZIP.Free;

  // Сообщение что все готово
  ShowMessage('ZES файл готов!');
end;

procedure TForm1.Button_Path_NESClick(Sender: TObject);
var
  name_dirty : String;
  name_clear: String;
begin
  if OpenDialog_Path_NES.Execute then
  begin
    // Копируем путь выбранного файла
    Edit_Path_NES.Text:= OpenDialog_Path_NES.FileName;
    // Получаем имя файла
    name_dirty := ExtractFileName(Edit_Path_NES.Text);
    // Удаляем расширение nes
    name_clear := StringReplace(name_dirty, '.nes', '', [rfReplaceAll, rfIgnoreCase]);
    // Записываем имя в поле Edit_Name_Game
    Edit_Name_Game.Text := name_clear;
  end;
end;

procedure TForm1.Button_Path_PNGClick(Sender: TObject);
begin
  if OpenDialog_Path_PNG.Execute then
  begin
       Edit_Path_PNG.Text:= OpenDialog_Path_PNG.FileName;
  end;
end;

// Вытаскиваем превьюшку
procedure TForm1.Button_Save_PNG_from_ZESClick(Sender: TObject);
var
  FS, FS2: TFileStream;
  buffer_size_png : LongInt;
  buffer_file_png : TByteArray;
  path_zes, name_zes , name_png : String;
begin
  if OpenDialog_ZES.Execute then
  begin
    // Открываем zes файл
    path_zes := OpenDialog_ZES.FileName;
    // Получаем имя
    name_zes := ExtractFileName(path_zes);
    // Меняем расширение с zes на png
    name_png := StringReplace(name_zes, '.zes', '.png', [rfReplaceAll, rfIgnoreCase]);

    // Получам размер png
    FS := TFileStream.Create(path_zes, fmOpenRead);
    FS.Position:= 512;
    FS.Read(buffer_size_png, 4);
    // Получам массив байт png
    FS.Position:= 520;
    FS.Read(buffer_file_png, buffer_size_png);
    FS.Free;
    // Сохраняю массив байт png в файл
    FS2 := TFileStream.Create(name_png, fmCreate);
    FS2.Write(buffer_file_png, buffer_size_png);
    FS2.Free;
    ShowMessage('Превьюшка успешно получена!');
  end;
end;

// Обнуление всех полей
procedure TForm1.Button_Resset_AllClick(Sender: TObject);
begin
  Edit_Name_Game.Clear;
  Edit_Path_NES.Clear;
  Edit_Path_PNG.Clear;
end;

// Ссылка на сайт программы
procedure TForm1.Label_link_homeClick(Sender: TObject);
begin
  OpenURL('https://github.com/Galavarez/Data_Frog_Y2_Hd_Plus');
end;


end.

