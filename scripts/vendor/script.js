$(document).ready(function(){
	// $('.card, .widgets').hide();
	// $('.card .bigpic').hide();

	// $('.marker').hover(function(){
	// 	$(this).find('.card').not('.active').filter(':not(:animated)').fadeIn(300);
	// }, function(){
	// 	$(this).find('.card').not('.active').filter(':not(:animated)').fadeOut(300);
	// });

	$('html, body, *').mousewheel(function(e, delta) {
		this.scrollLeft -= (delta * 40);
		e.preventDefault();
	});

	//CARD ACTIVE (FIXME: If only one can be active, shouldn't it be better to select it using its ID instead of class? //@glibersat)
	$('.card .inner').click(function(){
		card = $(this).parent('.card');
		widgets = card.siblings('.widgets');

		offset = card.offset();

		//WINDOW
		wH = $(window).height() - $('body > footer').height();
		wW = $(window).width();

		card.hide().addClass('active').height(wH).fadeIn(500);
		card.children('header').children('.minipic').hide();
		card.children('header').children('.bigpic').show();
		card.children('.inner').animate({ height:wH - $(this).siblings('header').outerHeight() - $(this).siblings('footer').outerHeight() }, 500, function(){
			card.find('.social').fadeIn(500);
			card.find('.supports-list').children('ul').children('li').each(function(i){
				$(this).delay(150*i).effect("bounce",1000);
			});
			widgets.css('top',card.css('top')).css('left',card.width() + 32);	
			widgets.height(wH).width(0);

			availableW=wW - card.width() - offset.left;
			if(availableW<440) { $('.description').width(availableW); }
			widgets.show().animate({width:availableW},1000);
		});
		//var sly = new Sly(card.find('.widgets'));     
		var frame= new Sly(widgets,{
			horizontal: 1,
			itemNav: 'basic',
			smart: 1,
			activateOn: null,
			mouseDragging: 1,
			touchDragging: 1,
			releaseSwing: 1,
			startAt: 0,
			scrollBy: 1,
			speed: 800,
			elasticBounds: 1,
			easing: 'easeOutExpo'
		}).init();

		frame.on('change',function(){
			widgets.width(wW -card.width());
			if(frame.pos.dest == 0) {
				card.parents('.marker').animate({left:'20%'},500);
				widgets.width(wW -card.width() - offset.left); 
			} else {
				card.parents('.marker').animate({left:'-32px'},500, function(){
					offset = card.offset();
					widgets.width(wW -card.width() - offset.left); 
				});
			}
		});
	});
	//WINDOW RESIZE
	$(window).resize(function(){
		//$('.card').hide().removeClass('active');

	});
});