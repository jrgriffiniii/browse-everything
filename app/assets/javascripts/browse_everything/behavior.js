'use strict';

/**
 * Class for interacting with the form element
 * @param form {Element|jQuery}
 */
function BrowseEverythingForm(form) {
  this.form = form;
  this.$form = $(form);
};

/**
 * Append a hidden <input> element for the form for a file entry
 * @param resource {BrowseEverythingResource}
 */
BrowseEverythingForm.prototype.appendFileInputElements = function(resource) {
  // Add the location
  var location_input = $("<input type='hidden' class='ev-url' name='browse_everything[selected_files][][location]'/>").val(resource.getLocation());
  this.$form.append(location_input);

  // Add the name
  var name_input = $("<input type='hidden' class='ev-url' name='browse_everything[selected_files][][name]'/>").val(resource.getName());
  this.$form.append(name_input);

  // Add the size
  var size_input = $("<input type='hidden' class='ev-url' name='browse_everything[selected_files][][size]'/>").val(resource.getSize());
  this.$form.append(size_input);

  // Add the type
  var type_input = $("<input type='hidden' class='ev-url' name='browse_everything[selected_files][][container]'/>").val(false);
  this.$form.append(type_input);

  var provider_input = $("<input type='hidden' class='ev-url' name='browse_everything[selected_files][][provider]'/>").val( resource.$element.data('ev-provider') );
  this.$form.append(provider_input);

  var type_input = $("<input type='hidden' class='ev-url' name='browse_everything[selected_files][][type]'/>").val( resource.$element.data('ev-type') );
  this.$form.append(type_input);
};

/**
 * Append a hidden <input> element for the form for a directory entry
 * @param resource {BrowseEverythingResource}
 */
BrowseEverythingForm.prototype.appendDirectoryInputElements = function(resource) {
  // Add the location
  var location_input = $("<input type='hidden' class='ev-url' name='browse_everything[selected_directories][][location]'/>").val(resource.getLocation());
  this.$form.append(location_input);

  // Add the name
  var name_input = $("<input type='hidden' class='ev-url' name='browse_everything[selected_directories][][name]'/>").val(resource.getName());
  this.$form.append(name_input);

  // Add the size
  var size_input = $("<input type='hidden' class='ev-url' name='browse_everything[selected_directories][][size]'/>").val(resource.getSize());
  this.$form.append(size_input);

  // Add the type
  var type_input = $("<input type='hidden' class='ev-url' name='browse_everything[selected_directories][][container]'/>").val(true);
  this.$form.append(type_input);

  // Add the provider
  var provider_input = $("<input type='hidden' class='ev-url' name='browse_everything[selected_directories][][provider]'/>").val( resource.$element.data('ev-provider') );
  this.$form.append(provider_input);

  var type_input = $("<input type='hidden' class='ev-url' name='browse_everything[selected_directories][][type]'/>").val( resource.$element.data('ev-type') );
  this.$form.append(type_input);
};

/**
 * Remove all hidden <input> elements for file or directory entries on the form
 * @param value {string}
 */
BrowseEverythingForm.prototype.removeFileInputElements = function(file_location) {
  this.$form.find('input[type="hidden"][value="' + file_location + '"]').remove();
};

/**
 * Class for resources selected for upload
 * @param element {Element|jQuery}
 */
function BrowseEverythingResource(element) {
  this.element = element;
  this.$element = $(element);
};

/*
 * Retrieve the location URI for the file resource
 * @return {string}
 */
BrowseEverythingResource.prototype.getLocation = function () {
  return this.$element.data('ev-location');
};

/*
 *
 * @return {string}
 */
BrowseEverythingResource.prototype.getName = function () {
  return this.$element.data('ev-file-name');
};

/*
 *
 * @return {string}
 */
BrowseEverythingResource.prototype.getSize = function () {
  return this.$element.data('ev-file-size');
};

/*
 * Static factory method for building objects
 * @param element {Element|jQuery}
 * @return {BrowseEverythingDirectory|BrowseEverythingFile}
 */
BrowseEverythingResource.build = function(element) {
  var $element = element;
  if ($element.data('tt-branch')) {
    return new BrowseEverythingDirectory(element);
  }

  return new BrowseEverythingFile(element);
}

/*
 * Class for file uploads
 * @param element {Element|jQuery}
 */
function BrowseEverythingFile(element) {
  BrowseEverythingResource.call(this, element);
};
BrowseEverythingFile.prototype = Object.create(BrowseEverythingResource.prototype);
BrowseEverythingFile.prototype.constructor = BrowseEverythingFile;

/*
 * Class for directory uploads
 * @param element {Element|jQuery}
 */
function BrowseEverythingDirectory(element) {
  BrowseEverythingResource.call(this, element);
};
BrowseEverythingDirectory.prototype = Object.create(BrowseEverythingResource.prototype);
BrowseEverythingDirectory.prototype.constructor = BrowseEverythingDirectory;

// Initial the global values and bind them to the global scope
window.browseEverything = {
  form: null
};

/**
 * jQuery-bound functionality
 */
$(function () {
  var dialog = $('div#browse-everything');
  var initialize = function initialize(obj, options) {
    if ($('div#browse-everything').length === 0) {
      // bootstrap 4 needs at least the inner class="modal-dialog" div, or it gets really
      // confused and can't close the dialog.
      dialog = $('<div tabindex="-1" id="browse-everything" class="ev-browser modal fade" aria-live="polite" role="dialog" aria-labelledby="beModalLabel">' + '<div class="modal-dialog modal-lg" role="document"></div>' + '</div>').hide().appendTo('body');
    }

    dialog.modal({
      backdrop: 'static',
      show: false
    });
    var ctx = {
      opts: $.extend(true, {}, options),
      callbacks: {
        show: $.Callbacks(),
        done: $.Callbacks(),
        cancel: $.Callbacks(),
        fail: $.Callbacks()
      }
    };
    ctx.callback_proxy = {
      show: function show(func) {
        ctx.callbacks.show.add(func);return this;
      },
      done: function done(func) {
        ctx.callbacks.done.add(func);return this;
      },
      cancel: function cancel(func) {
        ctx.callbacks.cancel.add(func);return this;
      },
      fail: function fail(func) {
        ctx.callbacks.fail.add(func);return this;
      }
    };
    $(obj).data('ev-state', ctx);
    return ctx;
  };

  var toHiddenFields = function toHiddenFields(data) {
    var fields = $.param(data).split('&').map(function (t) {
      return t.replace(/\+/g, ' ').split('=', 2);
    });
    var elements = $(fields).map(function () {
      return $("<input type='hidden'/>").attr('name', decodeURIComponent(this[0])).val(decodeURIComponent(this[1]))[0].outerHTML;
    });
    return $(elements.toArray().join("\n"));
  };

  var indicateSelected = function indicateSelected() {
    return $('input.ev-url').each(function () {
      return $('*[data-ev-location=\'' + $(this).val() + '\']').addClass('ev-selected');
    });
  };

  var fileIsSelected = function fileIsSelected(row) {
    var result = false;
    $('input.ev-url').each(function () {
      if (this.value === $(row).data('ev-location')) {
        return result = true;
      }
    });
    return result;
  };

  var toggleFileSelect = function toggleFileSelect(row) {
    row.toggleClass('ev-selected');
    if (row.hasClass('ev-selected')) {
      selectFile(row);
    } else {
      unselectFile(row);
    }
    return updateFileCount();
  };

  var selectFile = function selectFile(row) {
    var resource = BrowseEverythingResource.build(row);

    // Support the new API
    if (resource instanceof BrowseEverythingDirectory) {
      window.browseEverything.form.appendDirectoryInputElements(resource);
    } else {
      window.browseEverything.form.appendFileInputElements(resource);
    }

    if (!$(row).find('.ev-select-file').prop('checked')) {
      return $(row).find('.ev-select-file').prop('checked', true);
    }
  };

  var unselectFile = function unselectFile(row) {
    var resource = BrowseEverythingResource.build(row);
    window.browseEverything.form.removeFileInputElements(resource.getLocation());

    if ($(row).find('.ev-select-file').prop('checked')) {
      return $(row).find('.ev-select-file').prop('checked', false);
    }
  };

  var updateFileCount = function updateFileCount() {
    var count = $('input.ev-url').length;
    var files = count === 1 ? "file" : "files";
    return $('.ev-status').html(count + ' ' + files + ' selected');
  };

  var toggleBranchSelect = function toggleBranchSelect(row) {
    if (row.hasClass('collapsed')) {
      var node_id = row.find('td.ev-file-name a.ev-link').attr('href');
      return $('table#file-list').treetable('expandNode', node_id);
    }
  };

  var selectAll = function selectAll(rows) {
    return rows.each(function () {
      if ($(this).data('tt-branch')) {
        var box = $(this).find('#select_all')[0];
        $(box).prop('checked', true);
        $(box).prop('value', "1");
        return toggleBranchSelect($(this));
      } else {
        if (!fileIsSelected($(this))) {
          return toggleFileSelect($(this));
        }
      }
    });
  };

  var selectChildRows = function selectChildRows(row, action) {
    return $('table#file-list tr').each(function () {
      if ($(this).data('tt-parent-id')) {
        var re = RegExp($(row).data('tt-id'), 'i');
        if ($(this).data('tt-parent-id').match(re)) {
          if ($(this).data('tt-branch')) {
            var box = $(this).find('#select_all')[0];
            $(box).prop('value', action);
            if (action === "1") {
              $(box).prop("checked", true);
              var node_id = $(this).find('td.ev-file-name a.ev-link').attr('href');
              return $('table#file-list').treetable('expandNode', node_id);
            } else {
              return $(box).prop("checked", false);
            }
          } else {
            if (action === "1") {
              $(this).addClass('ev-selected');
              if (!fileIsSelected($(this))) {
                selectFile($(this));
              }
            } else {
              $(this).removeClass('ev-selected');
              unselectFile($(this));
            }
            return updateFileCount();
          }
        }
      }
    });
  };

  var tableSetup = function tableSetup(table) {
    table.treetable({
      expandable: true,
      onNodeCollapse: function onNodeCollapse() {
        var node = this;
        return table.treetable("unloadBranch", node);
      },
      onNodeExpand: function onNodeExpand() {
        var node = this;
        startWait();
        var size = $(node.row).find('td.ev-file-size').text().trim();
        var start = 1;
        var increment = 1;
        if (size.indexOf("MB") > -1) {
          start = 10;
          increment = 5;
        }
        if (size.indexOf("KB") > -1) {
          start = 50;
          increment = 10;
        }
        setProgress(start);
        var progressIntervalID = setInterval(function () {
          start = start + increment;
          if (start > 99) {
            start = 99;
          }
          return setProgress(start);
        }, 2000);
        return setTimeout(function () {
          return loadFiles(node, table, progressIntervalID);
        }, 10);
      }
    });
    $("#file-list tr:first").focus();
    return sizeColumns(table);
  };

  var sizeColumns = function sizeColumns(table) {
    var full_width = $('.ev-files').width();
    table.width(full_width);
    var set_size = function set_size(selector, pct) {
      return $(selector, table).width(full_width * pct).css('width', full_width * pct).css('max-width', full_width * pct);
    };
    set_size('.ev-file', 0.4);
    set_size('.ev-container', 0.4);
    set_size('.ev-size', 0.1);
    set_size('.ev-kind', 0.3);
    return set_size('.ev-date', 0.2);
  };

  var loadFiles = function loadFiles(node, table, progressIntervalID) {
    return $.ajax({
      async: true, // Must be false, otherwise loadBranch happens after showChildren?
      url: $('a.ev-link', node.row).attr('href'),
      data: {
        parent: node.row.data('tt-id'),
        accept: dialog.data('ev-state').opts.accept,
        context: dialog.data('ev-state').opts.context
      }
    }).done(function (html) {
      setProgress('100');
      clearInterval(progressIntervalID);
      var rows = $('tbody tr', $(html));
      table.treetable("loadBranch", node, rows);
      $(node).show();
      sizeColumns(table);
      indicateSelected();
      if ($(node.row).find('#select_all')[0].checked) {
        return selectAll(rows);
      }
    }).always(function () {
      clearInterval(progressIntervalID);
      return stopWait();
    });
  };

  var setProgress = function setProgress(done) {
    return $('.loading-text').text(done + '% complete');
  };

  var refreshFiles = function refreshFiles() {
    return $('.ev-providers select').change();
  };

  var startWait = function startWait() {
    $('.loading-progress').removeClass("hidden");
    $('body').css('cursor', 'wait');
    $("html").addClass("wait");
    $(".ev-browser").addClass("loading");
    return $('.ev-submit').attr('disabled', true);
  };

  var stopWait = function stopWait() {
    $('.loading-progress').addClass("hidden");
    $('body').css('cursor', 'default');
    $("html").removeClass("wait");
    $(".ev-browser").removeClass("loading");
    return $('.ev-submit').attr('disabled', false);
  };

  var handleScroll = function(event) {
    event.stopPropagation();
    event.preventDefault();

    var table = $('#file-list');
    var page = $('#file-list tfoot .ev-next-page').data('provider-contents-pages-next');

    var scrolled_offset = $(this).scrollTop();
    var height = $(this).innerHeight();
    var scrolled_height = this.scrollHeight;
    var window_offset = Math.ceil(scrolled_offset + height, 1);

    if (!((typeof page !== "undefined" && page !== null) && window_offset >= scrolled_height)) {
        return;
    }

    var provider_select = $('#provider-select');
    var url = provider_select.val();
    var table_body = table.find('tbody');
    var last_row = table_body.find('tr:last');

    $.ajax({
      url: url,
      data: {
        accept: dialog.data('ev-state').opts.accept,
        context: dialog.data('ev-state').opts.context,
        page_token: page
      }
    }).done(function(data) {
      var new_table = $(data);
      var new_rows = $(new_table).find('tbody tr');
      var new_table_foot = $(new_table).find('tfoot');

      table.find('tfoot').replaceWith(new_table_foot);
      table.treetable("loadBranch", null, new_rows);

      last_row.focus();
      sizeColumns(table);
      indicateSelected();
    }).fail(function(xhr,status,error) {
      if(xhr.responseText.indexOf("Refresh token has expired") > -1) {
        $('.ev-files').html("Your session has expired please clear your cookies.");
      } else {
        $('.ev-files').html(xhr.responseText);
      }
    }).always(function() {
      stopWait();
    });
  };

  // Handlers for DOM events
  $(window).on('resize', function () {
    return sizeColumns($('table#file-list'));
  });

  $.fn.browseEverything = function (options) {
    var ctx = $(this).data('ev-state');
    if (ctx == null && options == null) {
      options = $(this).data();
    }
    if (options != null) {
      ctx = initialize(this[0], options);
      $(this).click(function () {
        dialog.data('ev-state', ctx);
        return dialog.load(ctx.opts.route, function () {
          setTimeout(refreshFiles, 500);
          ctx.callbacks.show.fire();
          var $dialog = dialog.modal('show');
          var $form = $('form.ev-submit-form');
          window.browseEverything.form = new BrowseEverythingForm($form);
          return $dialog;
        });
      });
    }

    if (ctx) {
      return ctx.callback_proxy;
    } else {
      return {
        show: function show() {
          return this;
        },
        done: function done() {
          return this;
        },
        cancel: function cancel() {
          return this;
        },
        fail: function fail() {
          return this;
        }
      };
    }
  };

  $.fn.browseEverything.toggleCheckbox = function (box) {
    if (box.value === "0") {
      return $(box).prop('value', "1");
    } else {
      return $(box).prop('value', "0");
    }
  };

  $(document).on('ev.refresh', function (event) {
    return refreshFiles();
  });

  $(document).on('click', 'button.ev-cancel', function (event) {
    event.preventDefault();
    dialog.data('ev-state').callbacks.cancel.fire();
    return $('.ev-browser').modal('hide');
  });

  $(document).on('click', 'button.ev-submit', function (event) {
    event.preventDefault();
    $(this).button('loading');
    startWait();
    var main_form = $(this).closest('form');
    var resolver_url = main_form.data('resolver');
    var ctx = dialog.data('ev-state');
    $(main_form).find('input[name=context]').val(ctx.opts.context);
    return $.ajax(resolver_url, {
      type: 'POST',
      dataType: 'json',
      data: main_form.serialize()
    }).done(function (data) {
      if (ctx.opts.target != null) {
        var fields = toHiddenFields({ selected_files: data });
        $(ctx.opts.target).append($(fields));
      }
      return ctx.callbacks.done.fire(data);
    }).fail(function (xhr, status, error) {
      return ctx.callbacks.fail.fire(status, error, xhr.responseText);
    }).always(function () {
      $('body').css('cursor', 'default');
      $('.ev-browser').modal('hide');
      return $('#browse-btn').focus();
    });
  });

  $(document).on('click', '.ev-files a.ev-link', function (event) {
    event.stopPropagation();
    event.preventDefault();
    var row = $(this).closest('tr');
    var action = row.hasClass('expanded') ? 'collapseNode' : 'expandNode';
    var node_id = $(this).attr('href');
    return $('table#file-list').treetable(action, node_id);
  });

  $(document).on('change', '.ev-providers select', function (event) {
    event.preventDefault();
    startWait();

    var table_id = $(this).data('table-id');
    var table = $(table_id);
    var page = table.data('provider-contents-page-number');

    return $.ajax({
      url: $(this).val(),
      data: {
        accept: dialog.data('ev-state').opts.accept,
        context: dialog.data('ev-state').opts.context,
        page: page
      } }).done(function (data) {
      $('.ev-files').html(data);
      $('.ev-files').off('scroll.browseEverything');
      $('.ev-files').on('scroll.browseEverything', handleScroll);
      indicateSelected();
      $('#provider_auth').focus();
      return tableSetup($('table#file-list'));
    }).fail(function (xhr, status, error) {
      if (xhr.responseText.indexOf("Refresh token has expired") > -1) {
        return $('.ev-files').html("Your session has expired please clear your cookies.");
      } else {
        return $('.ev-files').html(xhr.responseText);
      }
    }).always(function () {
      return stopWait();
    });
  });

  $(document).on('click', '.ev-providers a', function (event) {
    $('.ev-providers li').removeClass('ev-selected');
    return $(this).closest('li').addClass('ev-selected');
  });

  $(document).on('click', '.ev-file a', function (event) {
    event.preventDefault();
    var target = $(this).closest('*[data-ev-location]');
    return toggleFileSelect(target);
  });

  $(document).on('click', '.ev-auth', function (event) {
    event.preventDefault();
    var auth_win = window.open($(this).attr('href'));
    var check_func = function check_func() {
      if (auth_win.closed) {
        return $('.ev-providers .ev-selected a').click();
      } else {
        return window.setTimeout(check_func, 1000);
      }
    };
    return check_func();
  });

  /**
   * Determine if an element is a container (i. e. directory)
   * @param element {Element|jQuery}
   * @return {boolean}
   */
  var isContainer = function (element) {
    var $target = $(element);
    var $td = $target.parent();
    var classes = $td.attr('class').split(' ');

    return classes.indexOf('ev-directory-select') != -1;
  };

  $(document).on('change', 'input.ev-select-all', function (event) {
    event.stopPropagation();
    event.preventDefault();
    $.fn.browseEverything.toggleCheckbox(this);
    var action = this.value;
    var row = $(this).closest('tr');
    var node_id = row.find('td.ev-file-name a.ev-link').attr('href');
    var $target = $(event.target);

    if (row.hasClass('collapsed')) {
      // Replace this BrowseEverythingResource type inferencing
      if (isContainer($target)) {
        var $tr = $target.parents('tr');
        return selectFile($tr);
      }

      return $('table#file-list').treetable('expandNode', node_id);
    } else {

      return selectChildRows(row, action);
    }
  });

  return $(document).on('change', 'input.ev-select-file', function (event) {
    event.stopPropagation();
    event.preventDefault();
    return toggleFileSelect($(this).closest('tr'));
  });
});

var auto_toggle = function auto_toggle() {
  var triggers = $('*[data-toggle=browse-everything]');
  if (typeof Rails !== 'undefined' && Rails !== null) {
    $.ajaxSetup({
      headers: { 'X-CSRF-TOKEN': (Rails || $.rails).csrfToken() || '' }
    });
  }

  return triggers.each(function () {
    var ctx = $(this).data('ev-state');
    if (ctx == null) {
      return $(this).browseEverything($(this).data());
    }
  });
};

if (typeof Turbolinks !== 'undefined' && Turbolinks !== null && Turbolinks.supported) {
  // Use turbolinks:load for Turbolinks 5, otherwise use the old way
  if (Turbolinks.BrowserAdapter) {
    $(document).on('turbolinks:load', auto_toggle);
  } else {
    $(document).on('page:change', auto_toggle);
  }
} else {
  $(document).ready(auto_toggle);
}
