

$(document).ready(function(){

  var jcrop_api;
  var $current_form;

  // on selecting a new file
  $(".file").on('change', function(){
      
      var input = this;
      var file = input.files && input.files[0];

      if(jcrop_api != null)
        jcrop_api.destroy();

      if( file ){
        var reader     = new FileReader();
        var input_elem = $(this);
        reader.onload = function(e){
          $img_elem = $('#image-preview');

          $('#myModal').modal('show');
          
          $img_elem.removeProp('style');
          $img_elem.prop('src', e.target.result);
          console.log(e);

          $current_form = input_elem.parents('.form');
          initJcrop();
        };

        reader.readAsDataURL(file);
      }
  });

  // change aspect ratio for diferent type of images
  $(".ctx-campaigns #image_type").on('change', function(e){
    var type = $(this).val();
    var aspect_ratio = 1
    switch(type){
      case 'strip':
        aspect_ratio = 640/246;
        break;
      default:
        aspect_ratio = 1;
    }
    jcrop_api.setOptions({ aspectRatio: aspect_ratio });

  });


  function initJcrop(){
    // initialize Jcrop api
    $('#image-preview').Jcrop({
      onChange: changeCoords
    }, function(){
        jcrop_api = this;
        $("#image_type").trigger('change');
    });

    var image          = $('#image-preview');
    var original_width = image.prop('naturalWidth');
    var resized_width  = image.width();
    var ratio          = original_width / resized_width;

    function changeCoords(coords){
      // console.log($current_form);
      $current_form.find('#crop_x').val(Math.round(coords.x * ratio));
      $current_form.find('#crop_y').val(Math.round(coords.y * ratio));
      $current_form.find('#width').val(Math.round(coords.w * ratio));
      $current_form.find('#height').val(Math.round(coords.h * ratio));
    }
  }

  $("#crop").on('click', function(){
    jcrop_api.destroy();
    $img_elem = $('#image-preview');
    $img_elem.hide();
  });

});
