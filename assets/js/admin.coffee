$(document).ready () ->
    $('.shows-table').on 'click', '.delete-btn', (evt) ->
        evt.preventDefault()
        id = $(this).data('id')
        $.ajax '/shows/' + id,
            method: 'DELETE'
            success: () => $(this).closest('tr').remove()
            error: () -> console.error "error deleting: #{id}"
