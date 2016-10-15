program Client;

uses
  Forms,
  UDataModule in 'UDataModule.pas' {FDM: TDataModule},
  UFormMain in 'UFormMain.pas' {fFormClient};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFDM, FDM);
  Application.CreateForm(TfFormClient, fFormClient);
  Application.Run;
end.
