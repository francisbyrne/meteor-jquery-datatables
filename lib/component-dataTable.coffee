findCellRowIndexes = (oSettings, sSearch, iColumn) ->
  i = undefined
  iLen = undefined
  j = undefined
  jLen = undefined
  aOut = []
  aData = undefined
  i = 0
  iLen = oSettings.aoData.length

  while i < iLen
    aData = oSettings.aoData[i]._aData
    if typeof iColumn is "undefined"
      j = 0
      jLen = aData.length

      while j < jLen
        aOut.push i  if aData[j] is sSearch
        j++
    else aOut.push i  if aData[iColumn] is sSearch
    i++
  aOut

Template.dataTable.default_template = 'default_table_template'

# Return the template specified in the component parameters
Template.dataTable.chooseTemplate = ( table_template = null ) ->
  table_template ?= Template.dataTable.default_template
  if Template[ table_template ]
    return Template[ table_template ]
  else return Template[ Template.dataTable.default_template ]

# Global defaults for all datatables
# These can be overridden in the options parameter
Template.dataTable.defaultOptions =
  #===== Default Table
  # * Pagination
  # * Filtering
  # * Sorting
  bJQueryUI: false
  bAutoWidth: true
  sPaginationType: "full_numbers"
  sDom: "<\"datatable-header\"fl><\"datatable-scroll\"t><\"datatable-footer\"ip>"
  oLanguage:
    sSearch: "_INPUT_"
    sLengthMenu: "<span>Show :</span> _MENU_"
    oPaginate:
      sFirst: "First"
      sLast: "Last"
      sNext: ">"
      sPrevious: "<"
  aoColumnDefs: []
  aaSorting: []

# Prepares the options object by merging the options passed in with the defaults
Template.dataTable.prepareOptions = ->
  self = @
  options = self.templateInstance.data.options or self.presetOptions() or {}
  columns = self.templateInstance.data.context.columns or []
  rows = self.templateInstance.data.context.rows or []
  if rows and columns
    if _.isArray rows
      options.aaData = rows
    if _.isArray columns
      options.aoColumns = columns
  self.templateInstance.data.options = _.defaults options, self.defaultOptions

# Creates an instance of dataTable with the given options and attaches it to this template instance
Template.dataTable.initialize = ->
  tI = @templateInstance
  selector = tI.data.selector
  options = tI.data.options
  rows = tI.data.context.rows

  #===== Initialize DataTable object and attach to templateInstance
  tI.dataTable = $(".#{selector} table").dataTable options

  #===== Setup observers to add and remove rows from the dataTable
  if _.isObject rows
    rows.observeChanges
      added: ( _id, fields ) ->
        fields._id = _id
        tI.dataTable.fnAddData fields
      changed: ( _id, fields ) ->
        oSettings = tI.dataTable.fnSettings()
        aoData = oSettings.aoData
        counter = 0
        index = 0
        aoData.forEach ( row ) =>
          if row._aData._id is _id
            index = counter
          counter++
        tI.dataTable.fnUpdate rows.collection.findOne( _id ), index
      moved: (document, oldIndex, newIndex) ->
        console.log("row moved: ", document)
      removed: ( _id ) ->
        oSettings = tI.dataTable.fnSettings()
        aoData = oSettings.aoData
        counter = 0
        index = 0
        aoData.forEach ( row ) =>
          if row._aData._id is _id
            index = counter
          counter++
        tI.dataTable.fnDeleteRow index

  #===== Datatable with footer filters
  if selector is 'datatable-add-row'
    $(".#{selector} .dataTables_wrapper tfoot input").keyup ->
      target = @
      tI.dataTable.fnFilter self.value, $(".#{selector} .dataTables_wrapper tfoot input").index( target )

  #===== Datatable results selector init
  if $().select2 isnt undefined
    $(".#{selector} .dataTables_length select").select2 minimumResultsForSearch: "-1"

  #===== Adding placeholder to Datatable filter input field =====//
  $(".#{selector} .dataTables_filter input[type=text]").attr "placeholder", "Type to filter..."


Template.dataTable.rendered = ->
  templateInstance = @
  component = templateInstance.__component__
  # Merge options with defaults
  component.prepareOptions()
  # Initialze DataTable
  component.initialize()

# TODO : this is temporary all of this should be passed in through the options param
Template.dataTable.presetOptions = ->
  self = @
  selector = self.templateInstance.data.selector

  #===== Table with tasks =====
  if selector is 'datatable-tasks'
    options =
      aoColumnDefs: [{
        bSortable: false
        aTargets: [5]
      }]

  #===== Table with invoices =====
  if selector is 'datatable-invoices'
    options =
      aoColumnDefs: [{
        bSortable: false
        aTargets: [
          1
          6
        ]
      }]
      aaSorting: [
        [
          0
          "desc"
        ]
      ]

  #===== Table with selectable rows =====
  if selector is 'datatable-selectable'
    options =
      sDom: "<\"datatable-header\"Tfl><\"datatable-scroll\"t><\"datatable-footer\"ip>"
      oTableTools:
        sRowSelect: "multi"
        aButtons: [{
          sExtends: "collection"
          sButtonText: "Tools <span class='caret'></span>"
          sButtonClass: "btn btn-primary"
          aButtons: [
            "select_all"
            "select_none"
          ]
        }]

  #===== Table with media objects
  if selector is 'datatable-media'
    options =
      aoColumnDefs: [
        bSortable: false
        aTargets: [
          0
          4
        ]
      ]

  #===== Table with two button pager
  if selector is 'datatable-pager'
    options =
      sPaginationType: "two_button"
      oLanguage:
        sSearch: "<span>Filter:</span> _INPUT_"
        sLengthMenu: "<span>Show entries:</span> _MENU_"
        oPaginate:
          sNext: "Next →"
          sPrevious: "← Previous"

  #===== Table with tools
  if selector is 'datatable-tools'
    options =
      sDom: "<\"datatable-header\"Tfl><\"datatable-scroll\"t><\"datatable-footer\"ip>"
      oTableTools:
        sRowSelect: "single"
        sSwfPath: "static/swf/copy_csv_xls_pdf.swf"
        aButtons: [{
          sExtends: "copy"
          sButtonText: "Copy"
          sButtonClass: "btn"
        },{
          sExtends: "print"
          sButtonText: "Print"
          sButtonClass: "btn"
        },{
          sExtends: "collection"
          sButtonText: "Save <span class='caret'></span>"
          sButtonClass: "btn btn-primary"
          aButtons: [
            "csv"
            "xls"
            "pdf"
          ]
        }]

  #===== Table with custom sorting columns
  if selector is 'datatable-custom-sort'
    options =
      aoColumnDefs: [{
        bSortable: false
        aTargets: [
          0
          1
        ]
      }]

  return options