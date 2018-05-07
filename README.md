# Validação de enumeration 
Essa classe serve para retornar uma lista de enumeration que receberam o valor "bound out" nos objetos de exportação do ACBrReinf, ou seja, um valor que não existe na coleção. 

# Exemplo de como usar
```delphi
var
  validaDados: TValidarEventosController;
  todosErros: String;
  nTabela: Integer;
  
Begin 
  Try
    ACBrReinf1.Enviar();
  Except
    On E: Exception Do
      Begin
         If (Pos(UpperCase('Access violation'), UpperCase(E.Message)) > 0) Then
            Begin
                validaDados := TValidarEventosController.Create(ACBrReinf1);
                Try
                   nTabela := 1000;
                   validaDados.fValidarDadosExportacao(nTabela, todosErros);
                   If (Trim(todosErros) <> '') Then
                      ShowMessage(todosErros);
                Finally
                   validaDados.Destroy;
                End;
            End; 
      End;
  End;
End;
```

### Aviso importante ### 
Essa classe sempre deve ser chamada no Except, como a classe é feita utilizando o RTTI foi necessário que a validação ficasse depois que já desse o erro, pois o RTTI quando lê uma propriedade ele aciona a função que estiver associada a ela. Então, a classe estava acionando eventos e esses eventos estavam dando create em propriedades não utilizadas e gerando problemas. 
