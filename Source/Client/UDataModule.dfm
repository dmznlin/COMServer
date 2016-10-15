object FDM: TFDM
  OldCreateOrder = False
  Left = 344
  Top = 157
  Height = 222
  Width = 346
  object edtStyle: TcxDefaultEditStyleController
    Style.Edges = [bBottom]
    Style.Font.Charset = GB2312_CHARSET
    Style.Font.Color = clBlack
    Style.Font.Height = -12
    Style.Font.Name = #23435#20307
    Style.Font.Style = []
    Style.TextColor = 4227072
    Style.IsFontAssigned = True
    StyleDisabled.Color = clWindow
    StyleFocused.Color = clInfoBk
    Left = 20
    Top = 128
    PixelsPerInch = 96
  end
  object dxLayout1: TdxLayoutLookAndFeelList
    Left = 72
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
    Left = 172
    Top = 128
  end
  object cxLoF1: TcxLookAndFeelController
    Kind = lfOffice11
    Left = 126
    Top = 126
  end
  object DBConn1: TUniConnection
    ProviderName = 'MySQL'
    LoginPrompt = False
    Left = 23
    Top = 16
  end
  object SQLQuery: TUniQuery
    Connection = DBConn1
    Left = 22
    Top = 68
  end
  object Command: TUniQuery
    Connection = DBConn1
    Left = 126
    Top = 68
  end
  object SqlTemp: TUniQuery
    Connection = DBConn1
    Left = 76
    Top = 68
  end
  object MySQL1: TMySQLUniProvider
    Left = 76
    Top = 16
  end
end
