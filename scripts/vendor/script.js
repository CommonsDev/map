$(document).ready(function(){
	$('html, body, *').mousewheel(function(e, delta) {
		this.scrollLeft -= (delta * 40);
		e.preventDefault();
	});

	wH = $(window).height();
	wW = $(window).width();
	$('.card.active .inner').height(wH - 308 - 135);

	$(document).on('click','.map-bg-panel form li', function() {
		$('.map-bg-panel li input').attr('checked',"");
	    $(this).children('input').attr("checked", "checked");
	    $('.map-bg-panel li').removeClass('active');
	    $(this).addClass('active');
	});
});