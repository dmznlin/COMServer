object fFormLogin: TfFormLogin
  Left = 0
  Top = 0
  ClientHeight = 551
  ClientWidth = 365
  Caption = #30331#24405
  ShowTitle = False
  CloseButton.Visible = False
  TitleButtons = <>
  OnCreate = UnimLoginFormCreate
  OnClose = UnimLoginFormClose
  PixelsPerInch = 96
  TextHeight = 13
  ScrollPosition = 0
  ScrollHeight = 0
  PlatformData = {}
  object PanelMain: TUnimContainerPanel
    Left = 0
    Top = 0
    Width = 365
    Height = 551
    Hint = ''
    Align = alClient
    AlignmentControl = uniAlignmentClient
    LayoutAttribs.Align = 'center'
    object ImageLogo: TUnimImage
      Left = 0
      Top = 0
      Width = 365
      Height = 132
      Hint = ''
      Align = alTop
      Stretch = True
      Url = 'Images/Logo.bmp'
    end
    object PanelLogin: TUnimContainerPanel
      Left = 0
      Top = 132
      Width = 365
      Height = 240
      Hint = ''
      Align = alTop
      Layout = 'hbox'
      object PanelL: TUnimContainerPanel
        Left = 0
        Top = 0
        Width = 25
        Height = 240
        Hint = ''
        Align = alLeft
        Flex = 1
      end
      object PanelM: TUnimContainerPanel
        Left = 25
        Top = 0
        Width = 315
        Height = 240
        Hint = ''
        Align = alClient
        Flex = 8
        object EditUser: TUnimEdit
          AlignWithMargins = True
          Left = 3
          Top = 3
          Width = 309
          Height = 47
          Hint = ''
          Align = alTop
          Text = ''
          EmptyText = #29992#25143#21517
          ParentFont = False
          LayoutConfig.Margin = '5'
          TabOrder = 1
        end
        object EditPwd: TUnimEdit
          AlignWithMargins = True
          Left = 3
          Top = 56
          Width = 309
          Height = 47
          Hint = ''
          Align = alTop
          Text = ''
          PasswordChar = '#'
          EmptyText = #30331#24405#23494#30721
          ParentFont = False
          LayoutConfig.Margin = '5'
          TabOrder = 2
        end
        object CheckPassword: TUnimToggle
          AlignWithMargins = True
          Left = 3
          Top = 109
          Width = 309
          Height = 38
          Hint = ''
          FieldLabel = #35760#20303#23494#30721
          FieldLabelAlign = laRight
          Align = alTop
          LayoutConfig.Margin = '5'
        end
        object BtnLogin: TUnimButton
          AlignWithMargins = True
          Left = 3
          Top = 153
          Width = 309
          Height = 47
          Hint = ''
          Align = alTop
          Caption = #30331#24405#31995#32479
          LayoutConfig.Margin = '5'
          OnClick = BtnLoginClick
        end
      end
      object PanelR: TUnimContainerPanel
        Left = 340
        Top = 0
        Width = 25
        Height = 240
        Hint = ''
        Align = alRight
        Flex = 1
      end
    end
    object UnimLabel1: TUnimLabel
      AlignWithMargins = True
      Left = 3
      Top = 525
      Width = 359
      Height = 23
      Hint = ''
      Alignment = taRightJustify
      AutoSize = False
      Caption = 'CopyRight'#169'2022'
      Align = alBottom
      LayoutConfig.Margin = '8'
      ParentFont = False
    end
  end
end
