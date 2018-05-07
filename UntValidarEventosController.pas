unit UntValidarEventosController;

interface

uses
  ACBrReinfEventos, TypInfo, System.Rtti, ACBrReinf,
  System.Classes, Dialogs, SysUtils, System.IniFiles, pcnConversaoReinf;

type
  rParametrosValidaPropriedades = record
    objItem: TObject;
    nomeClasse: String;
    MsgErro: String;
    IdRegistro: String;
  end;

  TValidarEventosController = class
  private
    FTabela: Integer;
    FACBrReinf: TACBrReinf;

    procedure pValidaPropriedades(dados: rParametrosValidaPropriedades; var MsgErro: String; var IdRegistro: String);
    function  fValidarDadosExportacao(listaEventos: TOwnedCollection; nTabela: Integer; out MsgErro: String): Boolean; overload;
    function  GetItensExportacaoACBr(AACBrReinf: TACBrReinf; nTabela: Integer): TOwnedCollection;
  public
    constructor Create(AACBrReinf: TACBrReinf);
    function  fValidarDadosExportacao(nTabela: Integer; out MsgErro: String): Boolean; overload;
  end;

implementation

uses
  pcnReinfR1000, pcnReinfR1070, pcnReinfR2010, pcnReinfR2020, pcnReinfR2030,
  pcnReinfR2040, pcnReinfR2050, pcnReinfR2060, pcnReinfR2070, pcnReinfR2098,
  pcnReinfR2099, pcnReinfR3010, pcnReinfR9000;

{ TValidarEventos }

procedure TValidarEventosController.pValidaPropriedades(dados: rParametrosValidaPropriedades;
  var MsgErro: String; var IdRegistro: String);
var
  ctxRtti: TRttiContext;
  typRtti: TRttiType;
  prpRtti: TRttiProperty;

  valor: TValue;
  objeto: TObject;
  classe: TClass;
  nValor: Integer;

  cNome, valorEnum: String;
  cNomeClassePai: String;
  novosDados: rParametrosValidaPropriedades;
begin
   ctxRtti := TRttiContext.Create;
   Try
      Try
         typRtti := ctxRtti.GetType(dados.objItem.ClassType);

         { Propertys de uma classe }
         For prpRtti In typRtti.GetProperties Do
            Begin
               { Pular qualquer propriedade herdada }
               cNomeClassePai := TRttiInstanceType(prpRtti.Parent).MetaclassType.ClassName;
               If ( cNomeClassePai <> dados.nomeClasse ) Then Continue;

               valor := prpRtti.GetValue(dados.objItem);

               { Validar se for coleção }
               If ( valor.TypeInfo.Kind = TTypeKind.tkEnumeration ) Then
                  Begin

                     cNome := valor.TypeInfo.Name;
                     valorEnum := valor.ToString;
                     nValor := GetEnumValue(valor.TypeInfo, valorEnum);
                     Try
                        If ( nValor = -1 ) Then
                           MsgErro := MsgErro +
                                      sLineBreak + ' ' +
                                      Copy(cNomeClassePai,2,Length(cNomeClassePai)-1) + '.' +
                                      cNome;

                     Except
                        On E: Exception Do
                           Begin
                              ShowMessage(E.Message);
                           End;
                     End;
                  End

               { Chamar de forma recursiva a função se for uma classe }
               Else If ( valor.TypeInfo.Kind = TTypeKind.tkClass ) Then
                  Begin
                     classe := valor.TypeData.ClassType;
                     objeto := valor.AsType<TObject>;
                     novosDados.nomeClasse := valor.TypeInfo.Name;
                     novosDados.objItem := objeto;

                     { Recursividade }
                     pValidaPropriedades(novosDados, MsgErro, IdRegistro);
                  End;
            End;
      Except
         On E: Exception Do
            Begin
               ShowMessage(E.Message);
            End;
      End;
   Finally
      ctxRtti.Free;
   End;
end;

function TValidarEventosController.fValidarDadosExportacao(listaEventos: TOwnedCollection;
  nTabela: Integer; out MsgErro: String): Boolean;
var
  ctxRtti: TRttiContext;
  evento: TObject;
  dados: rParametrosValidaPropriedades;
  nContador: Integer;
  todosErros: String;
begin
   Result := True;
   If Not Assigned(listaEventos) Then Exit;

   FTabela := nTabela;
   dados.nomeClasse := listaEventos.Items[0].ClassName;
   ctxRtti := TRttiContext.Create;
   Try
      nContador := 0;
      For evento In TOwnedCollection(listaEventos) Do
         Begin
            Try
               dados.objItem := evento;
               dados.MsgErro := '';
               dados.IdRegistro   := '';
               pValidaPropriedades(dados, dados.MsgErro, dados.IdRegistro);

               nContador := nContador+1;
               If ( Trim(dados.MsgErro) <> '' ) Then
                  Begin
                     dados.MsgErro := '[Evento nº: '+IntToStr(nContador)+']' + dados.MsgErro;
                     todosErros := todosErros + dados.MsgErro + sLineBreak + sLineBreak;
                  End;
            Except
               On E: Exception Do
                  Begin
                     ShowMessage(E.Message);
                  End;
            End;
         End;

      If ( Trim(todosErros) <> '' ) Then
         Begin
            Result := False;
            todosErros := 'Lista de campos não preenchidos: ' +
                             sLineBreak +
                             sLineBreak +
                             todosErros;
                                         
            MsgErro := todosErros;
         End;
   Finally
      ctxRtti.Free;
   End;
end;

constructor TValidarEventosController.Create(AACBrReinf: TACBrReinf);
begin
   FACBrReinf := AACBrReinf;
end;

function TValidarEventosController.fValidarDadosExportacao(nTabela: Integer;
  out MsgErro: String): Boolean;
var
  validaDadosExportacao: TOwnedCollection;
begin
   validaDadosExportacao := GetItensExportacaoACBr(FACBrReinf, nTabela);
   Result := fValidarDadosExportacao(validaDadosExportacao, nTabela, MsgErro);
end;

function TValidarEventosController.GetItensExportacaoACBr(
  AACBrReinf: TACBrReinf; nTabela: Integer): TOwnedCollection;
begin
   Case nTabela Of
      1000: Result := AACBrReinf.Eventos.ReinfEventos.R1000;
      1070: Result := AACBrReinf.Eventos.ReinfEventos.R1070;
      2010: Result := AACBrReinf.Eventos.ReinfEventos.R2010;
      2020: Result := AACBrReinf.Eventos.ReinfEventos.R2020;
      2030: Result := AACBrReinf.Eventos.ReinfEventos.R2030;
      2040: Result := AACBrReinf.Eventos.ReinfEventos.R2040;
      2050: Result := AACBrReinf.Eventos.ReinfEventos.R2050;
      2060: Result := AACBrReinf.Eventos.ReinfEventos.R2060;
      2070: Result := AACBrReinf.Eventos.ReinfEventos.R2070;
      2098: Result := AACBrReinf.Eventos.ReinfEventos.R2098;
      2099: Result := AACBrReinf.Eventos.ReinfEventos.R2099;
      3010: Result := AACBrReinf.Eventos.ReinfEventos.R3010;
      9000: Result := AACBrReinf.Eventos.ReinfEventos.R9000;
   End;
end;

end.
