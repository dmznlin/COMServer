inherited fFormTruckVIP: TfFormTruckVIP
  Caption = #36710#36742#21015#34920
  OnCreate = UnimFormCreate
  OnDestroy = UnimFormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  ScrollPosition = 0
  ScrollHeight = 47
  PlatformData = {}
  object PanelMain: TUnimContainerPanel
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 314
    Height = 474
    Hint = ''
    Align = alClient
    AlignmentControl = uniAlignmentClient
    LayoutConfig.Padding = '1'
    LayoutConfig.Margin = '2'
    object PanelTop: TUnimContainerPanel
      Left = 0
      Top = 0
      Width = 314
      Height = 35
      Hint = ''
      Align = alTop
      Layout = 'hbox'
      object EditTruck: TUnimEdit
        Left = 0
        Top = 0
        Width = 244
        Height = 35
        Hint = ''
        Align = alClient
        Text = ''
        EmptyText = #36755#20837#36710#29260#21495#26597#25214
        ParentFont = False
        TabOrder = 1
        OnChange = EditTruckChange
      end
      object BtnFind: TUnimButton
        Left = 244
        Top = 0
        Width = 70
        Height = 35
        Hint = ''
        Align = alRight
        Caption = #21047#26032
        IconCls = 'search'
        UI = 'confirm'
        OnClick = BtnFindClick
      end
    end
    object DBGrid1: TUnimDBGrid
      Left = 0
      Top = 35
      Width = 314
      Height = 404
      Hint = ''
      Align = alClient
      DataSource = DataSource1
      Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgConfirmDelete, dgRowNumbers]
      WebOptions.PageSize = 100
      OnClick = DBGrid1Click
      Columns = <
        item
          Alignment = taCenter
          Title.Caption = #36873#20013
          FieldName = 'Checked'
          Width = 59
        end
        item
          Title.Caption = #36710#29260#21495#30721
          FieldName = 'T_Truck'
          Width = 100
        end
        item
          Title.Caption = #29366#24577
          FieldName = 'T_Valid'
          Width = 150
        end
        item
          Title.Caption = #31867#22411
          FieldName = 'T_Allow'
          Width = 64
        end
        item
          Title.Caption = #25805#20316#20154
          FieldName = 'T_User'
          Width = 64
        end
        item
          Title.Caption = #25805#20316#26102#38388
          FieldName = 'T_Time'
          Width = 64
        end>
    end
    object PanelBottom: TUnimContainerPanel
      Left = 0
      Top = 439
      Width = 314
      Height = 35
      Hint = ''
      Align = alBottom
      Layout = 'hbox'
      object BtnDel: TUnimButton
        Left = 0
        Top = 0
        Width = 95
        Height = 35
        Hint = ''
        ShowHint = True
        ParentShowHint = False
        Align = alLeft
        Caption = #21024#38500
        IconCls = 'delete'
        UI = 'action'
        OnClick = BtnDelClick
      end
      object BtnDelQuery: TUnimButton
        Left = 95
        Top = 0
        Width = 95
        Height = 35
        Hint = ''
        ShowHint = True
        ParentShowHint = False
        Align = alLeft
        Caption = #26597#35810#21024#38500
        IconCls = 'search'
        UI = 'action'
        OnClick = BtnDelQueryClick
      end
      object BtnAdd: TUnimButton
        Left = 224
        Top = 0
        Width = 90
        Height = 35
        Hint = ''
        Align = alRight
        Caption = #28155#21152
        IconCls = 'add'
        UI = 'action'
        OnClick = BtnAddClick
      end
    end
  end
  object DataSource1: TDataSource
    DataSet = MTable1
    Left = 141
    Top = 107
  end
  object MenuBottom: TUnimMenu
    Items = <
      item
        Caption = #20840#37096#36873#20013
        MenuId = 0
      end
      item
        Caption = #20840#37096#21462#28040
        MenuId = 1
      end
      item
        Caption = #20840#37096#21453#36873
        MenuId = 2
      end>
    Side = msBottom
    Cover = True
    Visible = False
    OnClick = MenuBottomClick
    Left = 87
    Top = 159
  end
  object MTable1: TkbmMemTable
    DesignActivation = True
    AttachedAutoRefresh = True
    AttachMaxCount = 1
    FieldDefs = <>
    IndexDefs = <>
    SortOptions = []
    PersistentBackup = False
    ProgressFlags = [mtpcLoad, mtpcSave, mtpcCopy]
    LoadedCompletely = False
    SavedCompletely = False
    FilterOptions = []
    Version = '7.74.00 Professional Edition'
    LanguageID = 0
    SortID = 0
    SubLanguageID = 1
    LocaleID = 1024
    Left = 83
    Top = 107
  end
end
