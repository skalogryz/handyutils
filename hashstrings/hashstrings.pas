unit HashStrings;
{
  The unit is THashedStringList
  developed by Dmitry Boyarintsev 9/22/2012
  * added fast key adjustement TStringHas.ModifyKeys
  * added changes handling for put, delete and insert functionality in THashedStringList
}

interface

{$ifdef fpc}{$mode delphi}{$h+}{$endif}

uses
  SysUtils, Classes;

type
  PPHashItem = ^PHashItem;
  PHashItem = ^THashItem;
  THashItem = record
    Next: PHashItem;
    Key: string;
    Value: Integer;
  end;

  TStringHash = class
  private
    Buckets: array of PHashItem;
  protected
    function Find(const Key: string): PPHashItem;
    function HashOf(const Key: string): Longword; virtual;
  public
    constructor Create(Size: Longword = 256);
    destructor Destroy; override;
    procedure Add(const Key: string; Value: Integer);
    procedure Clear;
    procedure Remove(const Key: string);
    function Modify(const Key: string; Value: Integer): Boolean;
    function ValueOf(const Key: string): Integer;
    procedure ModifyValues(const MinValue, Delta: Integer);
  end;

  THashedStringList = class(TStringList)
  private
    FValueHash: TStringHash;
    FNameHash: TStringHash;
    FValueHashValid: Boolean;
    FNameHashValid: Boolean;
    procedure UpdateValueHash;
    procedure UpdateNameHash;
  protected
    fChangeHandled: Integer;
    procedure Changed; override;
    procedure InsertItem(Index: Integer; const S: string; AObject: TObject); override;
    procedure Put(Index: Integer; const S: string); override;
    procedure PutObject(Index: Integer; AObject: TObject); override;

  public
    DoDebug : Boolean;
    destructor Destroy; override;
    procedure Delete(Index: Integer); override;

    function IndexOf(const S: string): Integer; override;
    function IndexOfName(const Name: string): Integer; override;
  end;

implementation

{ TStringHash }

procedure TStringHash.Add(const Key: string; Value: Integer);
var
  Hash: Integer;
  Bucket: PHashItem;
begin
  Hash := HashOf(Key) mod Longword(Length(Buckets));
  New(Bucket);
  Bucket^.Key := Key;
  Bucket^.Value := Value;
  Bucket^.Next := Buckets[Hash];
  Buckets[Hash] := Bucket;
end;

procedure TStringHash.Clear;
var
  I: Integer;
  P, N: PHashItem;
begin
  for I := 0 to Length(Buckets) - 1 do
  begin
    P := Buckets[I];
    while P <> nil do
    begin
      N := P^.Next;
      Dispose(P);
      P := N;
    end;
    Buckets[I] := nil;
  end;
end;

constructor TStringHash.Create(Size: Longword);
begin
  inherited Create;
  SetLength(Buckets, Size);
end;

destructor TStringHash.Destroy;
begin
  Clear;
  inherited Destroy;
end;

function TStringHash.Find(const Key: string): PPHashItem;
var
  Hash: Integer;
begin
  Hash := HashOf(Key) mod Longword(Length(Buckets));
  Result := @Buckets[Hash];
  while Result^ <> nil do
  begin
    if Result^.Key = Key then
      Exit
    else
      Result := @Result^.Next;
  end;
end;

function TStringHash.HashOf(const Key: string): Longword;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to Length(Key) do
    Result := ((Result shl 2) or (Result shr (SizeOf(Result) * 8 - 2))) xor
      Ord(Key[I]);
end;

function TStringHash.Modify(const Key: string; Value: Integer): Boolean;
var
  P: PHashItem;
begin
  P := Find(Key)^;
  if P <> nil then
  begin
    Result := True;
    P^.Value := Value;
  end
  else
    Result := False;
end;

procedure TStringHash.ModifyValues(const MinValue, Delta: Integer);
var
  i : integer;
  b : PHashItem;
begin
  for i:=0 to length(Buckets)-1 do begin
    if not Assigned(Buckets[i]) then Continue;
    b:=Buckets[i];
    while Assigned(b) do begin
      if b^.Value>=MinValue then inc(b^.Value, Delta);
      b:=b^.Next;
    end;
  end;
end;

procedure TStringHash.Remove(const Key: string);
var
  P: PHashItem;
  Prev: PPHashItem;
begin
  Prev := Find(Key);
  P := Prev^;
  if P <> nil then
  begin
    Prev^ := P^.Next;
    Dispose(P);
  end;
end;

function TStringHash.ValueOf(const Key: string): Integer;
var
  P: PHashItem;
begin
  P := Find(Key)^;
  if P <> nil then
    Result := P^.Value
  else
    Result := -1;
end;

{ THashedStringList }

procedure THashedStringList.Changed;
begin
  inherited Changed;
  if fChangeHandled=0 then begin
    FValueHashValid := False;
    FNameHashValid := False;
  end;
end;

procedure THashedStringList.Delete(Index: Integer);
var
  nm : string;
  v  : string;
begin
  if Assigned(FValueHash) or Assigned(FNameHash) then begin
    inc(fChangeHandled);
    try
      nm:=Names[index];
      v:=Strings[index];
      inherited Delete(Index);

      if Assigned(FValueHash) then begin
        FValueHash.Remove(v);
        FValueHash.ModifyValues(Index, -1);
      end;
      if Assigned(FNameHash) then begin
        if not CaseSensitive then FNameHash.Remove(AnsiUpperCase(nm)) 
        else FNameHash.Remove(nm);
        FNameHash.ModifyValues(Index, -1);
      end;
    finally
      dec(fChangeHandled);
    end
  end else
    inherited Delete(Index);
end;

destructor THashedStringList.Destroy;
begin
  FValueHash.Free;
  FNameHash.Free;
  inherited Destroy;
end;

function THashedStringList.IndexOf(const S: string): Integer;
begin
  UpdateValueHash;
  if not CaseSensitive then
    Result := FValueHash.ValueOf(AnsiUpperCase(S))
  else
    Result := FValueHash.ValueOf(S);
end;

function THashedStringList.IndexOfName(const Name: string): Integer;
begin
  UpdateNameHash;
  if not CaseSensitive then
    Result := FNameHash.ValueOf(AnsiUpperCase(Name))
  else
    Result := FNameHash.ValueOf(Name);
end;

procedure THashedStringList.InsertItem(Index: Integer; const S: string;
  AObject: TObject);
var
  Key : string;
  P   : Integer;
begin
  if Assigned(FValueHash) or Assigned(FNameHash) then begin
    inc(fChangeHandled);
    try
      inherited InsertItem(Index, S, AObject);

      if Assigned(FValueHash) then begin
        FValueHash.ModifyValues(Index, 1);
        if not CaseSensitive then FValueHash.Add( AnsiUpperCase(S), Index)
        else FValueHash.Add(S, Index);
      end;

      if Assigned(FNameHash) then begin
        FNameHash.ModifyValues(Index, 1);
        Key := Get(Index);
        P := AnsiPos(NameValueSeparator, Key);
        if P <> 0 then begin
          if not CaseSensitive then Key := AnsiUpperCase(Copy(Key, 1, P - 1))
          else Key := Copy(Key, 1, P - 1);
          FNameHash.Add(Key, Index);
        end;
      end;
    finally
      dec(fChangeHandled);
    end;
  end else
    inherited InsertItem(Index, S, AObject);
end;

procedure THashedStringList.Put(Index: Integer; const S: string);
var
  v       : String;
  P       : Integer;
  oldkey  : String;
  newkey  : String;
begin
  if Assigned(FValueHash) or Assigned(FNameHash) then begin
    
    inc(fChangeHandled);
    v:=Get(Index);
    inherited;
    if Assigned(FValueHash) then
      if not CaseSensitive then begin
        FValueHash.Remove(AnsiUpperCase(v));
        FValueHash.Add(AnsiUpperCase(S), Index);
      end else begin
        FValueHash.Remove(v);
        FValueHash.Add(S, Index);
      end;

    if Assigned(FNameHash) then begin
      P := AnsiPos(NameValueSeparator, v);
      if P <> 0 then begin
        if not CaseSensitive then oldkey:=AnsiUpperCase(Copy(V, 1, P - 1))
        else oldkey := Copy(V, 1, P - 1);
      end;
      P := AnsiPos(NameValueSeparator, S);
      if P <> 0 then begin
        if not CaseSensitive then newkey := AnsiUpperCase(Copy(S, 1, P - 1))
        else newkey := Copy(S, 1, P - 1);
      end;
      if (newkey<>oldkey) then begin
        FNameHash.Remove(oldkey);
        FNameHash.Add(newkey, Index);
      end;
    end;

    dec(fChangeHandled);
  end else begin
    inherited;
  end;
end;

procedure THashedStringList.PutObject(Index: Integer; AObject: TObject);
begin
  inc(fChangeHandled);
  inherited;
  dec(fChangeHandled);
end;

procedure THashedStringList.UpdateNameHash;
var
  I: Integer;
  P: Integer;
  Key: string;
begin
  if FNameHashValid then Exit;

  if FNameHash = nil then
    FNameHash := TStringHash.Create
  else
    FNameHash.Clear;
  for I := 0 to Count - 1 do
  begin
    Key := Get(I);
    P := AnsiPos(NameValueSeparator, Key);
    if P <> 0 then
    begin
      if not CaseSensitive then
        Key := AnsiUpperCase(Copy(Key, 1, P - 1))
      else
        Key := Copy(Key, 1, P - 1);
      FNameHash.Add(Key, I);
    end;
  end;
  FNameHashValid := True;
end;

procedure THashedStringList.UpdateValueHash;
var
  I: Integer;
begin
  if FValueHashValid then Exit;

  if FValueHash = nil then
    FValueHash := TStringHash.Create
  else
    FValueHash.Clear;
  for I := 0 to Count - 1 do
    if not CaseSensitive then
      FValueHash.Add(AnsiUpperCase(Self[I]), I)
    else
      FValueHash.Add(Self[I], I);
  FValueHashValid := True;
end;

end.
