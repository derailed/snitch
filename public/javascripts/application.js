var refresh_con   = 1;
var refresh_graph = 1;
     
function toggle_panel( name )
{                          
	var panel = $( name );
  if( Element.visible( name ) )
  {
    new Effect.BlindUp( name, { duration:1 } );
  }
  else
  {
	  new Effect.BlindDown( name, { duration:1 } ); 
  }
} 

// Turn refresh off
function refresh_off()
{
  refresh_con = 0;
  $('refresh').innerHTML = 'Refresh Off';
  new Effect.Highlight( 'refresh', { duration: 3, endcolor: "#2d2d2d" } );
}
     
// Toggles refresh flag and refresh link
function toggle_refresh()
{
  refresh_con = refresh_con == 1 ? 0 : 1;
  $('refresh').innerHTML = refresh_con == 1 ? 'Refresh On' : 'Refresh Off';
  new Effect.Highlight( 'refresh', { duration: 3, endcolor: "#2d2d2d" } );
}

// Toggle details info off or on
function display_details( id )
{   
  var flag = 0;   
  if ( $('toggle_details').innerHTML == "Expanded view" ) 
    flag = 1;
  else 
    flag = 0;
                                                                                           
  if ( flag == 0 ) 
    Element.hide( id );		   
  else 
    Element.show( id );
}  

// Toggle details info off or on
function toggle_details()
{   
  var flag = 0;   
  if ( $('toggle_details').innerHTML == "Expanded view" ) 
  {
    flag = 0;
    $('toggle_details').innerHTML = "List view";
   }
   else 
   {
     flag = 1;
     $('toggle_details').innerHTML = "Expanded view";   
   }
                                                                                           
   details = document.getElementsByClassName( 'log_params', $('content') );
   for( var i = 0; i < details.length; i++ )
   {
     if ( flag == 0 ) 
	     Element.hide( details[i].id );		   
     else 
	     Element.show( details[i].id );
	 }
}  