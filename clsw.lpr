program clsw;

{$MODE DELPHI}

uses
  SysUtils, Classes, Windows;

type
  CLS_CALLBACK = function(Instance: Pointer; callback_operation: Integer;
    ptr: Pointer; n: Integer): Integer; cdecl;

var
  Inp, Outp: TStream;
  ClsMain: function(operation: Integer; Callback: CLS_CALLBACK;
    Instance: Pointer): Integer; cdecl;

function Callback(Instance: Pointer; callback_operation: Integer; ptr: Pointer;
  n: Integer): Integer; cdecl;
var
  Bytes: TBytes;
begin
  Result := -2;
  if (callback_operation = $1000) or
    (callback_operation = $1400) then
    Result := Inp.Read(ptr^, n);
  if (callback_operation = $1800) or
    (callback_operation = $1C00) then
    Result := Outp.Write(ptr^, n);
  if callback_operation = 1 then
  begin
    GetMem(ptr, n);
    Result := 0;
  end;
  if callback_operation = 2 then
  begin
    Freemem(ptr);
    Result := 0;
  end;
  if callback_operation = 3 then
  begin
    Setlength(Bytes, Length(Paramstr(2)));
    Bytes := BytesOf(Paramstr(2));
    Move(Bytes[0], Pbyte(ptr)^, Length(Paramstr(2)));
    Result := 0;
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
      CLSName := 'arc-' + Copy(Paramstr(1), 3, Length(Paramstr(1)) - 2)
        + '.dll';
    DLLHandle := LoadLibrary(PChar(CLSName));
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
      Writeln(errOutput, ClsMain(3, Callback, nil))
    else if Paramstr(1).StartsWith('d') then
      Writeln(errOutput, ClsMain(4, Callback, nil));
    FreeLibrary(DLLHandle);
    Inp.Free;
    Outp.Free;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
