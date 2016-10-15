program Client;

uses
  JclAppInst,
  Forms,
  UDataModule in 'UDataModule.pas' {FDM: TDataModule},
  UFormMain in 'UFormMain.pas' {fFormClient};

{$R *.res}

begin
  JclAppInstances.CheckSingleInstance;
  Application.Initialize;
  Application.CreateForm(TFDM, FDM);
  Application.CreateForm(TfFormClient, fFormClient);
  Application.Run;
end.
