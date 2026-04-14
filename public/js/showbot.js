jQuery(document).ready(function() {
  // Timeago
  $("abbr.timeago").timeago().show().timeago();

  // Tippy tooltips on timeago elements (shows full datetime on hover)
  tippy('abbr.timeago', {
    placement: 'left',
    animation: 'fade'
  });

  // Modernizr
  if (Modernizr.touch) {
    // Remove hover events for touch devices since they screw up rendering
    $(".hover").removeClass("hover");
  }

  // Show the heart since it starts off hidden
  $('.heart').show();

  // Table Sorting
  $("table.sortable").tablesorter({
    textExtraction: table_text_extraction,
    sortList: [[0, 1]]
  });

  // Setup Votes
  setup_voting();
});

// Extract text from cells that aren't normal.
// Returns a String of text that represents the cell for sorting purposes.
function table_text_extraction(element) {
  var $element = $(element);
  var text = $element.html();

  // If this is a date column, extract the text for sorting
  if ($element.find('abbr').length) {
    text = $element.find('abbr').data('epoch-time');
  // Extract vote count value if this is a vote column.
  // Also required for sorting to continue working after a vote is cast.
  } else if ($element.find('.vote_count').length) {
    text = $element.find('.vote_count').html();
  }

  return text;
}

function setup_voting() {
  $(document).on('click', 'a.vote_up', function(e) {
    e.preventDefault();
    var $link = $(this);
    var $vote_count = $link.siblings('.vote_count').first();

    // Do nothing if already marked as voted
    if ($vote_count.hasClass('voted')) {
      return;
    } else {
      $vote_count.addClass('voted');
    }

    var id = $link.data('id');

    $.get("/titles/" + id + "/vote_up", function(response) {
      if (response != null) {
        var $vote_arrow = $link.find('.vote_arrow');
        $vote_arrow.addClass('launch');
        // Wait for the launch animation to finish
        setTimeout(function() {
          $vote_arrow.remove();
        }, 800); // 0.2 seconds less than animation due to hide

        var vote_amount = parseInt(response.votes);
        if (isNaN(vote_amount)) {
          $vote_count.addClass('error');
        } else {
          $vote_count.text(vote_amount);

          if (response.cluster_top) {
            $link.closest('tr').children('.cluster-votes').text(response.cluster_votes);
          } else {
            $link.closest('tr').siblings('#cluster-' + response.cluster_id).children('.cluster-votes').text(response.cluster_votes);
          }
        }

        // Update sort cache so the table re-sorts on the new vote value
        $link.parents('table').trigger('update');
      }
    }, "json").fail(function() {
      $vote_count.removeClass('voted');
      $vote_count.addClass('error');
    });
  });
}
