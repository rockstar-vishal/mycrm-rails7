// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require dataTables/jquery.dataTables
//= require dataTables/bootstrap/3/jquery.dataTables.bootstrap
//= require popper
//= require moment
//= require fullcalendar
//= require bootstrap
//= require cocoon
//= require chosen-jquery
//= require jquery.multi-select
//= require chartkick
//= require clipboard
//= require Chart.bundle
//= require pusher
//= require adminlte.min
//= require jquery-tablesorter
//= require jquery.datetimepicker
//= require_tree .


$(document).ready(function() {
  handleAdvanceSearch();
  handleSubscription();
  handlePusherSubscription();
  bulkSelectOperations();
  singleSelectOperations();
  toggleShowMoreLess();
  initializeTableSorter();
  togglePassword();
  initiateCalender();
  initiateLeadCalender();
  $(".dataTables").dataTable({
    "iDisplayLength": 50,
    responsive: true,
    bPaginate: false,
    bFilter: false
  });
  $('.multi-select-list').multiSelect({
    keySelect: [32],
    selectableOptgroup: false,
    disabledClass: 'disabled',
    dblClick: false,
    keepOrder: false,
    cssClass: ''
  });

  // Initialize multiselect elements
  $('.multiselect').multiSelect({
    keySelect: [32],
    selectableOptgroup: false,
    disabledClass: 'disabled',
    dblClick: false,
    keepOrder: false,
    cssClass: ''
  });

  document.querySelectorAll('.tomselect-checkbox').forEach(function(el) {
  new TomSelect(el, {
    maxItems: 30,
    plugins: {
      'clear_button': {},
      'remove_button': {},
      'dropdown_input': {},
      'checkbox_options': {
        checkedClassNames:   ['ts-checked'],
        uncheckedClassNames: ['ts-unchecked']
      }
    }
  });
});

  // Single select TomSelect configuration
  document.querySelectorAll('.tomselect-single').forEach(function(el) {
  new TomSelect(el, {
    maxItems: 1,
    plugins: {
      'clear_button': {},
      'dropdown_input': {}
    }
  });
});


  // clipboard js

  // Initialize tooltips for Bootstrap 5
  var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
  tooltipTriggerList.map(function (tooltipTriggerEl) {
    return new bootstrap.Tooltip(tooltipTriggerEl);
  });

  // For clipboard buttons, use data attributes for tooltips
  $('.clipboard-btn').attr('data-bs-toggle', 'tooltip').attr('data-bs-placement', 'top');

  $('.chosen-select').chosen({
    allow_single_deselect: true,
    no_results_text: 'No results matched',
    width: '350px'
  });

  $('#company_cost_sheet_letter_types_chosen').attr('style', 'width: 250px !important;');

  function setTooltip(btn, message) {
    // For Bootstrap 5, we need to use the new API
    var tooltip = bootstrap.Tooltip.getInstance(btn);
    if (tooltip) {
      tooltip.hide();
    }
    $(btn).attr('data-bs-original-title', message);
    tooltip = new bootstrap.Tooltip(btn);
    tooltip.show();
  }

  function hideTooltip(btn) {
    setTimeout(function() {
      var tooltip = bootstrap.Tooltip.getInstance(btn);
      if (tooltip) {
        tooltip.hide();
      }
    }, 1000);
  }

  var clipboard = new Clipboard('.clipboard-btn');
  clipboard.on('success', function(e) {
    setTooltip(e.trigger, 'Copied!');
    hideTooltip(e.trigger);
  });

  clipboard.on('error', function(e) {
    setTooltip(e.trigger, 'Failed!');
    hideTooltip(e.trigger);
  });

  // clipboard js ends
  var date = new Date();
  var today = new Date(date.getFullYear(), date.getMonth(), date.getDate());
  $('.datetimepicker').datetimepicker({dateFormat: "yy-mm-dd HH:ii:ss"});
  $('.datetimepickerncd').datetimepicker({dateFormat: "yy-mm-dd HH:ii:ss", minDate: today});
  $('.datetimepickerleaseexpired').datetimepicker({timepicker: false,format:'d/m/Y', maxDate: today});
  // For Modal - Bootstrap 5
  document.addEventListener('show.bs.modal', function(event) {
    if (event.target.id === 'modal-window') {
      $('.datetimepicker').datetimepicker({dateFormat: "yy-mm-dd HH:ii:ss"});
      $('.datetimepickerncd_modal').datetimepicker({dateFormat: "yy-mm-dd HH:ii:ss", minDate: today});
      $('.dateFormat').datetimepicker({
        timepicker: false,
        format:'d/m/Y'
      });
    }
  });
  
  // Fix Bootstrap 5 modal close button focus issues
  document.addEventListener('hide.bs.modal', function(event) {
    if (event.target.id === 'modal-window') {
      // Remove focus from any focused elements before hiding
      var focusedElement = event.target.querySelector(':focus');
      if (focusedElement) {
        focusedElement.blur();
      }
    }
  });
  
  // Handle modal close button clicks properly
  $(document).on('click', '.modal .close[data-bs-dismiss="modal"]', function(e) {
    e.preventDefault();
    // Remove focus before closing
    this.blur();
    // Get the modal instance and hide it
    var modalElement = this.closest('.modal');
    var modal = bootstrap.Modal.getInstance(modalElement);
    if (modal) {
      modal.hide();
    }
  });
  $('.dateFormat').datetimepicker({
    timepicker: false,
    format:'d/m/Y'
  });


});
function handleAdvanceSearch() {
  if (!$('.drawer-backdrop').length) {
    $('body').append('<div class="drawer-backdrop"></div>');
  }
  
  if (!$('#adv-searchbox .drawer-close-btn').length) {
    $('#adv-searchbox').prepend('<button class="drawer-close-btn" type="button">&times;</button>');
  }
  
  var isAnimating = false;
  
  function closeDrawer() {
    if (isAnimating) return;
    
    var searchBox = $('#adv-searchbox');
    var icon = $('#adv-search').children('i');
    var backdrop = $('.drawer-backdrop');
    
    if (searchBox.hasClass('drawer-open')) {
      isAnimating = true;
      searchBox.addClass('drawer-closing');
      backdrop.removeClass('active');
      setTimeout(function() {
        searchBox.removeClass('drawer-open drawer-closing');
        isAnimating = false;
      }, 400);
      icon.removeClass('fa-angle-up').addClass('fa-angle-down');
    }
  }
  
  function openDrawer() {
    if (isAnimating) return;
    
    var searchBox = $('#adv-searchbox');
    var icon = $('#adv-search').children('i');
    var backdrop = $('.drawer-backdrop');
    
    isAnimating = true;
    searchBox.removeClass('drawer-closing');
    requestAnimationFrame(function() {
      searchBox.addClass('drawer-open');
      backdrop.addClass('active');
      setTimeout(function() {
        isAnimating = false;
      }, 400);
    });
    icon.removeClass('fa-angle-down').addClass('fa-angle-up');
  }
  
  $('#adv-search').click(function() {
    var searchBox = $('#adv-searchbox');
    
    if (searchBox.hasClass('drawer-open')) {
      closeDrawer();
    } else {
      openDrawer();
    }
  });
  
  $(document).on('click', '.drawer-backdrop', function() {
    closeDrawer();
  });
  
  $(document).on('click', '.drawer-close-btn', function() {
    closeDrawer();
  });
}


function bulkSelectOperations() {
  $('.select-all').on('change', function() {
    if(this.checked) {
      $('.bulk-select').each(function() {
        this.checked = true;
      });
      $('div.bulk-process').show();
    } else {
      $('.bulk-select').each(function() {
        this.checked = false;
      });
      $('div.bulk-process').hide();
    }
  });
}

function singleSelectOperations() {
  $('input.bulk-select').on('change', function() {
    if($('input.bulk-select:checked').length) {
      $('div.bulk-process').show();
    } else {
      $('div.bulk-process').hide();
    }
  });
}

function toggleShowMoreLess(){
  var moretext = "Show more >";
  var lesstext = "Show less <";
  $('.showmore').each(function() {
    var ellipsestext = "...";
    showChar = 50
    var content = $(this).html();
    if(content.length > showChar) {
      var c = content.substr(0, showChar);
      var h = content.substr(showChar, content.length - showChar);
      var html = c + '<span class="moreellipses">' + ellipsestext + '&nbsp;</span><span class="morecontent"><span>' + h + '</span>&nbsp;&nbsp;<a href="javascript:void(0)" class="morelink">' + moretext + '</a></span>';
      $(this).html(html);
    }
  });
  $(".morelink").click(function(){
    if($(this).hasClass("less")) {
      $(this).removeClass("less");
      $(this).html(moretext);
    } else {
      $(this).addClass("less");
      $(this).html(lesstext);
    }
    $(this).parent().prev().toggle();
    $(this).prev().toggle();
    return false;
  });
}
function initializeTableSorter() {
  $('.custom-sorter').tablesorter({
    showProcessing: true,
    // initialize zebra and filter widgets
    widgets: ["zebra", "filter", "cssStickyHeaders"],
    headers: {
    },
    widgetOptions: {
      cssStickyHeaders_offset: 63,
      cssStickyHeaders_addCaption: true
    }
  });

  $("#basic-data-table").DataTable({
    "bPaginate": false,
    "fixedHeader" : {
      "header": true,
      "headerOffset": 50
    },
    "bSort": false
  });
}
var a = ['','one ','two ','three ','four ', 'five ','six ','seven ','eight ','nine ','ten ','eleven ','twelve ','thirteen ','fourteen ','fifteen ','sixteen ','seventeen ','eighteen ','nineteen '];
var b = ['', '', 'twenty','thirty','forty','fifty', 'sixty','seventy','eighty','ninety'];
function inWords (num) {
    if ((num = num.toString()).length > 9) return 'overflow';
    n = ('000000000' + num).substr(-9).match(/^(\d{2})(\d{2})(\d{2})(\d{1})(\d{2})$/);
    if (!n) return; var str = '';
    str += (n[1] != 0) ? (a[Number(n[1])] || b[n[1][0]] + ' ' + a[n[1][1]]) + 'crore ' : '';
    str += (n[2] != 0) ? (a[Number(n[2])] || b[n[2][0]] + ' ' + a[n[2][1]]) + 'lakh ' : '';
    str += (n[3] != 0) ? (a[Number(n[3])] || b[n[3][0]] + ' ' + a[n[3][1]]) + 'thousand ' : '';
    str += (n[4] != 0) ? (a[Number(n[4])] || b[n[4][0]] + ' ' + a[n[4][1]]) + 'hundred ' : '';
    str += (n[5] != 0) ? ((str != '') ? 'and ' : '') + (a[Number(n[5])] || b[n[5][0]] + ' ' + a[n[5][1]]) + '' : '';
    return str;
  }

function togglePassword(){
  $("#show_hide_password a").on('click', function(event) {
    event.preventDefault();
    if($('#show_hide_password input').attr('type') == 'text'){
      $('#show_hide_password input').attr('type', 'password');
      $('#show_hide_password i').addClass( "fa-eye-slash" );
      $('#show_hide_password i').removeClass( "fa-eye" );
      } else if($('#show_hide_password input').attr('type') == 'password') {
      $('#show_hide_password input').attr('type', 'text');
      $('#show_hide_password i').removeClass( "fa-eye-slash" );
      $('#show_hide_password i').addClass( "fa-eye" );
    }
  });
}


function handleSubscription(){
  if (gon.can_subscribe){
    (function(p,u,s,h,x){p.pushpad=p.pushpad||function(){(p.pushpad.q=p.pushpad.q||[]).push(arguments)};h=u.getElementsByTagName('head')[0];x=u.createElement('script');x.async=1;x.src=s;h.appendChild(x);})(window,document,'https://pushpad.xyz/pushpad.js');
    pushpad('init', gon.project_id, {serviceWorkerPath: '/service-worker.js'});
    if (window.sessionStorage.getItem('notification-status') != 'subscribed'){
      pushpad('subscribe', function () {
        window.sessionStorage.setItem('notification-status', 'subscribed');
      });
    }
    pushpad('tags', ['web_app']);
    pushpad('uid', gon.user_uuid, gon.hmac_signature);
  }
}

function initiateCalender(){
  $('#calendar').fullCalendar({
    header: {
      left: 'prev,next today',
      center: 'title',
      today:    'hoy',
      month:    'month',
      week:     'week',
      day:      'day',
      right: 'month,agendaWeek,agendaDay'
    },
    events: '/reports/scheduled_site_visits.json',
    eventClick: function(event, element) {
      var event_id = event.id
      var url = '/reports/'+event_id+'/scheduled_site_visits_detail/'
      if ($(element.target).attr('value') == "Edit"){
        url = '/leads/'+event_id+'/edit/'
      }
      $.ajax({
        type: 'GET',
        url: url,
        dataType: 'script'
      });
    },
    eventRender: function(eventObj, element){
      element.find('.fc-content').append("<span class='fc-edit pull-right'><i class='fa fa-pencil' value='Edit'></i></span>");
    }
  });
}

function initiateLeadCalender() {
  $('#lead-calendar').fullCalendar({
    themeSystem: 'bootstrap',
    header: {
      left: 'prev,next today',
      center: 'title',
      today:    'hoy',
      month:    'month',
      week:     'week',
      day:      'day',
      right: 'month,agendaWeek,agendaDay'
    },
    events: function(start, end, timezone, callback) {
      var searchParams = $('#calender_view_search').serializeArray();
      var params = searchParams.reduce(function(acc, param) {
        var name = param.name;
        var value = param.value;

        if (name.endsWith('[]')) {
          acc[name] = acc[name] || [];
          acc[name].push(value);
        } else {
          acc[name] = value;
        }
        return acc;
      }, {
        start: start.format(),
        end: end.format()
      });

      $.ajax({
        url: 'calender_view.json',
        type: 'GET',
        data: params,
        success: callback,
        error: function() {
          alert('There was an error while fetching events!');
        }
      });
    },
    eventClick: function(event, element) {
      var event_id = event.id;
      var url = '/reports/' + event_id + '/scheduled_site_visits_detail/';
      if ($(element.target).attr('value') === "Edit") {
        url = '/leads/' + event_id + '/edit/';
      }
      $.ajax({
        type: 'GET',
        url: url,
        dataType: 'script'
      });
    },
    eventRender: function(eventObj, element) {
      element.find('.fc-content').append("<span class='fc-edit pull-right'><i class='fa fa-pencil' value='Edit'></i></span>");
    }
  });
}

// Reinitialize TomSelect fields after modal content loads
$(document).on('shown.bs.modal', function() {
  // Reinitialize tomselect-checkbox fields
  document.querySelectorAll('.tomselect-checkbox').forEach(function(el) {
    // Check if TomSelect is already initialized
    if (!el.classList.contains('ts-hidden-accessible')) {
      new TomSelect(el, {
        maxItems: 30,
        plugins: {
          'clear_button': {},
          'remove_button': {},
          'dropdown_input': {},
          'checkbox_options': {
            checkedClassNames:   ['ts-checked'],
            uncheckedClassNames: ['ts-unchecked']
          }
        }
      });
    }
  });
  
  // Reinitialize tomselect-single fields
  document.querySelectorAll('.tomselect-single').forEach(function(el) {
    // Check if TomSelect is already initialized
    if (!el.classList.contains('ts-hidden-accessible')) {
      new TomSelect(el, {
        maxItems: 1,
        plugins: {
          'clear_button': {},
          'dropdown_input': {}
        }
      });
    }
  });
});

