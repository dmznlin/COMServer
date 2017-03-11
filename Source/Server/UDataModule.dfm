object FDM: TFDM
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Left = 344
  Top = 157
  Height = 222
  Width = 346
  object dxLayout1: TdxLayoutLookAndFeelList
    Left = 21
    Top = 126
    object dxLayoutWeb1: TdxLayoutWebLookAndFeel
      GroupOptions.CaptionOptions.Color = clSkyBlue
      GroupOptions.CaptionOptions.SeparatorWidth = 1
      GroupOptions.FrameColor = clBackground
      GroupOptions.OffsetCaption = False
      ItemOptions.CaptionOptions.Font.Charset = GB2312_CHARSET
      ItemOptions.CaptionOptions.Font.Color = clWindowText
      ItemOptions.CaptionOptions.Font.Height = -12
      ItemOptions.CaptionOptions.Font.Name = #23435#20307
      ItemOptions.CaptionOptions.Font.Style = []
      ItemOptions.CaptionOptions.UseDefaultFont = False
      Offsets.ControlOffsetHorz = 2
      Offsets.ItemOffset = 3
    end
  end
  object XPM1: TXPManifest
    Left = 126
    Top = 127
  end
  object cxLoF1: TcxLookAndFeelController
    Kind = lfOffice11
    Left = 75
    Top = 126
  end
  object DBConn1: TUniConnection
    ProviderName = 'MySQL'
    LoginPrompt = False
    Left = 23
    Top = 19
  end
  object SQLQuery: TUniQuery
    Connection = DBConn1
    Left = 22
    Top = 68
  end
  object Command: TUniQuery
    Connection = DBConn1
    Left = 128
    Top = 68
  end
  object SqlTemp: TUniQuery
    Connection = DBConn1
    Left = 76
    Top = 68
  end
  object MySQL1: TMySQLUniProvider
    Left = 128
    Top = 19
  end
  object DBConn2: TUniConnection
    ProviderName = 'MySQL'
    LoginPrompt = False
    Left = 76
    Top = 19
  end
end
