$(document).ready(function(){
	$('html, body, *').mousewheel(function(e, delta) {
		this.scrollLeft -= (delta * 40);
		e.preventDefault();
	});

	wH = $(window).height();
	wW = $(window).width();
	$('.card.active .inner').height(wH - 308 - 135);

	$('.map-bg-panel form img').click(function(){
		$(this).siblings('input').click();
	});
});