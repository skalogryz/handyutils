{
  Free to any use - distribution, changes and modification w/o any notice.
  Dmitry 'skalogryz' Boyarintsev - Aug 2018

}
unit StrTemplateCore;

{$ifdef fpc}{$mode delphi}{$H+}{$endif}

interface

type
  TTempSection = class(TObject)
    ofs     : Integer;
    len     : Integer;
    isText  : Boolean;
    valName : String;

    next    : TTempSection;
  end;

  { TTemplate }

  TTemplate = class(TObject)
  protected
    lastSection : TTempSection;
    function AddSection: TTempSection; overload;
    function AddSection(ofs, len: Integer;
      AIsText: Boolean = true; const vlName: string = ''): TTempSection;
  public
    text: String;
    firstSection : TTempSection;
    sectionsCount: Integer;
    destructor Destroy; override;
  end;

procedure ParseTemplate(const str: string; dst: TTemplate); overload;
function ParseTemplate(const str: string): TTemplate; overload;

const
  TEMP_MARK = '%';

type
  TValSource = class(TObject) // interface, anyone?
  public
    function LenOf(const val: string): Integer; virtual; abstract;
    function CopyTo(const val: string; var dst: String; ofs: Integer): Integer; virtual; abstract;
  end;

function FillTemplate(tmp: TTemplate; src: TValSource): string; overload;
function FillTemplate(const s: string; src: TValSource): string; overload;

implementation

function FillTemplate(tmp: TTemplate; src: TValSource): string;
var
  i  : Integer;
  sz : Integer;
  t  : TTempSection;
begin
  if not Assigned(tmp) or not Assigned(src) then begin
    Result:='';
    Exit;
  end;
  sz := 0;
  t := tmp.firstSection;
  writeln('t = ', PtrUInt(t));
  while Assigned(t) do begin
    if t.isText then inc(sz, t.len)
    else inc(sz, src.LenOf(t.valName));
    t:=t.next;
  end;

  if sz=0 then begin
    Result := '';
    Exit;
  end;

  SetLength(Result, sz);
  i:=1;
  t := tmp.firstSection;
  while Assigned(t) do begin
    if t.isText then begin
      Move(tmp.text[t.ofs], Result[i], t.len);
      inc(i, t.len);
    end else
      inc(i, src.CopyTo(t.valName, Result, i));
    t:=t.next;
  end;
end;

function FillTemplate(const s: string; src: TValSource): string;
var
  tmp : TTemplate;
begin
  tmp := ParseTemplate(s);
  try
    Result := FillTemplate(tmp, src);
  finally
    tmp.Free;
  end;
end;

function ParseTempMark(const str: string; var idx: Integer): string;
var
  i : integer;
begin
  if (idx<=length(str)) and (str[idx]=TEMP_MARK) then inc(idx);
  i:=idx;
  while (idx<=length(str)) and (str[idx]<>TEMP_MARK) do inc(idx);

  Result:=Copy(str, i, idx-i);

  if (idx<=length(str)) then inc (idx);
end;

procedure ParseTemplate(const str: string; dst: TTemplate); overload;
var
  i : integer;
  j : integer;
  vl : string;
begin
  if not Assigned(dst) then Exit;

  dst.text:=str;
  if str='' then begin
    dst.AddSection(1,0, true);
    Exit;
  end;

  i:=1;
  j:=1;
  while i <= length(str) do begin
    if (str[i] = TEMP_MARK) then begin
      if (i < length(str)) and (str[i+1]=TEMP_MARK) then
      begin
        dst.AddSection(j, i-j+1, true);
        inc(i,2);
        j:=i;
      end else begin
        if j<i then dst.AddSection(j, i-j);
        j:=i;
        vl := ParseTempMark(str, i);
        dst.AddSection(j, i-j, false, vl);
        j:=i;
      end;
    end else
      inc(i);
  end;
  if j<i then dst.AddSection(j, i-j);
end;

function ParseTemplate(const str: string): TTemplate; overload;
begin
  Result:=TTemplate.Create;
  ParseTemplate(str, Result);
end;

{ TTemplate }

function TTemplate.AddSection: TTempSection;
begin
  Result:=TTempSection.Create;
  if not Assigned(firstSection) then firstSection:=Result;
  if Assigned(lastSection) then lastSection.next := Result;
  lastSection:=Result;
  inc(sectionsCount);
end;

function TTemplate.AddSection(ofs, len: Integer; AIsText: Boolean;
  const vlName: string): TTempSection;
begin
  Result:=AddSection;
  Result.ofs:=ofs;
  Result.len:=len;
  Result.isText:=AIsText;
  Result.valName:=vlName;
end;

destructor TTemplate.Destroy;
var
  t : TTempSection;
  p : TTempSection;
begin
  t := firstSection;
  while Assigned(t) do begin
    p:=t.next;
    t.Free;
    t:=p;
  end;
  inherited Destroy;
end;

end.

