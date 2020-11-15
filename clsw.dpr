program clsw;

{$APPTYPE CONSOLE}
{$R *.res}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

uses
  System.SysUtils, System.Classes, WinAPI.Windows;
{$SETPEFLAGS IMAGE_FILE_RELOCS_STRIPPED}

type
  CLS_CALLBACK = function(Instance: Pointer; callback_operation: Integer;
    ptr: Pointer; n: Integer): Integer; cdecl;

var
  AInstance: Pointer;
  Inp, Outp: TStream;
  ClsMain: function(operation: Integer; Callback: CLS_CALLBACK;
    Instance: Pointer): Integer; cdecl;

const
  CLS_INIT = 1;
  CLS_DONE = 2;
  CLS_FLUSH = 6;

  CLS_COMPRESS = 3;
  CLS_DECOMPRESS = 4;
  CLS_PREPARE_METHOD = 5;

  CLS_FULL_READ = 4096;
  CLS_PARTIAL_READ = 5120;
  CLS_FULL_WRITE = 6144;
  CLS_PARTIAL_WRITE = 7168;

  CLS_MALLOC = 1;
  CLS_FREE = 2;
  CLS_GET_PARAMSTR = 3;
  CLS_SET_PARAMSTR = 4;
  CLS_THREADS = 5;
  CLS_MEMORY = 6;
  CLS_DECOMPRESSION_MEMORY = 7;
  CLS_DECOMPRESSOR_VERSION = 8;
  CLS_BLOCK = 9;
  CLS_EXPAND_DATA = 10;

  CLS_ID = 101;
  CLS_VERSION = 102;
  CLS_THREAD_SAFE = 103;

  CLS_OK = 0;
  CLS_ERROR_GENERAL = -1;
  CLS_ERROR_NOT_IMPLEMENTED = -2;
  CLS_ERROR_NOT_ENOUGH_MEMORY = -3;
  CLS_ERROR_READ = -4;
  CLS_ERROR_WRITE = -5;
  CLS_ERROR_ONLY_DECOMPRESS = -6;
  CLS_ERROR_INVALID_COMPRESSOR = -7;
  CLS_ERROR_BAD_COMPRESSED_DATA = -8;
  CLS_ERROR_NO_MORE_DATA_REQUIRED = -9;
  CLS_ERROR_OUTBLOCK_TOO_SMALL = -10;

  CLS_PARAM_INT = -1;
  CLS_PARAM_STRING = -2;
  CLS_PARAM_MEMORY_MB = -3;

  CLS_MAX_PARAMSTR_SIZE = 256;
  CLS_MAX_ERROR_MSG = 256;
  { function ClsMain(operation: Integer; Callback: CLS_CALLBACK; Instance: Pointer)
    : Integer; cdecl; external 'cls-zstd.dll'; }

function Callback(Instance: Pointer; callback_operation: Integer; ptr: Pointer;
  n: Integer): Integer; cdecl;
var
  Bytes: TBytes;
begin
  Result := CLS_ERROR_NOT_IMPLEMENTED;
  if (callback_operation = CLS_FULL_READ) or
    (callback_operation = CLS_PARTIAL_READ) then
    Result := Inp.Read(ptr^, n);
  if (callback_operation = CLS_FULL_WRITE) or
    (callback_operation = CLS_PARTIAL_WRITE) then
    Result := Outp.Write(ptr^, n);
  if callback_operation = CLS_MALLOC then
  begin
    GetMem(ptr, n);
    Result := CLS_OK;
  end;
  if callback_operation = CLS_FREE then
  begin
    Freemem(ptr);
    Result := CLS_OK;
  end;
  if callback_operation = CLS_GET_PARAMSTR then
  begin
    Setlength(Bytes, Length(Paramstr(2)));
    Bytes := BytesOf(Paramstr(2));
    Move(Bytes[0], Pbyte(ptr)^, Length(Paramstr(2)));
    Result := CLS_OK;
  end;
end;

var
  DLLHandle: THandle;
  CLSName: String;

begin
  try
    if Paramcount < 3 then
      exit;
    if Copy(Paramstr(1), 2, 1) = ':' then
      CLSName := 'cls-' + Copy(Paramstr(1), 3, Length(Paramstr(1)) - 2)
        + '.dll';
    DLLHandle := LoadLibrary(PWideChar(CLSName));
    if (DLLHandle >= 32) then
      @ClsMain := GetProcAddress(DLLHandle, 'ClsMain')
    else
      exit;
    if Paramstr(Paramcount - 1) = '-' then
      Inp := THandleStream.Create(GetSTDHandle(STD_INPUT_HANDLE))
    else
      Inp := TFilestream.Create(Paramstr(Paramcount - 1), fmOpenRead);
    if Paramstr(Paramcount) = '-' then
      Outp := THandleStream.Create(GetSTDHandle(STD_OUTPUT_HANDLE))
    else
      Outp := TFilestream.Create(Paramstr(Paramcount), fmCreate);
    if Paramstr(1).StartsWith('c') then
      Writeln(errOutput, ClsMain(CLS_COMPRESS, Callback, AInstance))
    else if Paramstr(1).StartsWith('d') then
      Writeln(errOutput, ClsMain(CLS_DECOMPRESS, Callback, AInstance));
    FreeLibrary(DLLHandle);
    Inp.Free;
    Outp.Free;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
