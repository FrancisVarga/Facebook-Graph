package dareville.api.facebook.services.common
{
	import com.adobe.serialization.json.JSON;
	
	import dareville.api.facebook.FacebookConstants;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import org.osflash.signals.Signal;

	/**
	 * The <code>AbstractFacebookService</code> class provides abstract
	 * access to data. This class should be overriden to provide specific access 
	 * to different types of data.
	 * 
	 * @langversion ActionScript 3.0
	 * @playerversion Flash 9.0.124
	 * 
	 * @author kris@dareville.com
	 */
	public class AbstractFacebookService
	{
		//----------------------------------
		//  Signals
		//----------------------------------
		
		/**
		 * Signal dispatched when a service has errored. Dispatches a
		 * <code>String</code> as a parameter.
		 */		
		public var errored : Signal = new Signal( String );
		
		/**
		 * Signal dispatched when a service has deleted an item. Dispatches a
		 * <code>Boolean</code> as a parameter.
		 */		
		public var deleted : Signal = new Signal( Boolean );
		
		//---------------------------------------------------------------------
		//
		//  Public methods
		//
		//---------------------------------------------------------------------
		
		/**
		 * Constructor
		 */
		public function AbstractFacebookService()
		{
		}
		
		/**
		 * Abstract method to call a Facebook service. This method is provided
		 * so that developers can make undocumented calls or calls that might
		 * not yet be available within this API.
		 * 
		 * @param loader URLLoader to load with
		 * @param path The Facebook path to retrieve
		 * @param access_token The sessions access token
		 * @param data Any additional variables that need to be passed
		 * @param method GET/POST method
		 * @param api_path Specified path to the Facebook secure/unsecure URIs
		 * 
		 * @return Boolean
		 */		
		public function call( 
			loader : URLLoader,
			path : String,
			access_token : String,
			data : URLVariables = null,
			method : String = null,
			api_path : String = FacebookConstants.API_SECURE_PATH,
			metadata : Boolean = true ) : Boolean
		{
			if( access_token )
			{
				// If no data is provided, create a new instance and assign
				// access token
				data = data || new URLVariables();
				data.access_token = access_token;
				data.metadata = ( metadata ) ? 1 : 0;
				
				// If no method is provided, set to the default GET request method
				method = method || URLRequestMethod.GET;
				
				// Create the URL and the request
				var url : String = api_path + path;
				var request : URLRequest = new URLRequest( url );
				request.data = data;
				request.method = method;
				
				// Load the request
				loader.load( request );
				
				return true;
			}
			return false;
		}
		
		/**
		 * Deletes data asynchronously as long as the logged in user has access
		 * to delete the specified item.
		 * 
		 * <p>If the request succeeds, a <code>deleted</code> Signal is 
		 * dispatched containing an <code>Boolean</code> object.</p>
		 * 
		 * @param access_token Facebook access token
		 * @param item Item ID to delete
		 * 
		 * @return URLLoader Loader
		 */		
		public function deleteItem( 
			access_token : String, 
			item : String ) : URLLoader
		{
			if( access_token )
			{
				var loader : URLLoader = new URLLoader();
				loader.dataFormat = URLLoaderDataFormat.TEXT;
				loader.addEventListener( IOErrorEvent.IO_ERROR, onDeleteIOError, false, 0, true );
				loader.addEventListener( Event.COMPLETE, onDeleteComplete, false, 0, true );
				
				var data : URLVariables = new URLVariables();
				data.method = FacebookConstants.DELETE;
				
				// Call the service
				call( loader, item, access_token, data, URLRequestMethod.POST );
				return loader;
			}
			return null;
		}
		
		//---------------------------------------------------------------------
		//
		//  Protected methods
		//
		//---------------------------------------------------------------------
		
		/**
		 * @private
		 * Decode data received from a service. This decodes a JSON string into
		 * an object. If the JSON string is invalide, it will dispatch an
		 * <code>errored</code> Signal.
		 * 
		 * @param data String value of all the data to decode
		 * @return JSON encoded object 
		 */		
		protected function decodeData( data : String ) : Object
		{
			// Attempt to decode the JSON data and create the value object
			var json_data : Object;
			json_data = JSON.decode( data );
			try
			{
				json_data = JSON.decode( data );
			}
			// JSON was invalid so dispatch an error
			catch( error : Error )
			{
				errored.dispatch();
				return null;
			}
			
			return json_data;
		}
		
		//----------------------------------
		//  Handlers
		//----------------------------------
		
		/**
		 * @private
		 * Callback for when the delete request completes
		 * 
		 * @param event <code>Event.COMPLETE</code> 
		 */		
		private function onDeleteComplete( event : Event ) : void
		{
			// Get the loader and remove any event listeners first
			var loader : URLLoader = event.target as URLLoader;
			loader.removeEventListener( IOErrorEvent.IO_ERROR, onDeleteIOError );
			loader.removeEventListener( Event.COMPLETE, onDeleteComplete );
			
			var json_data : Object = decodeData( loader.data );
			deleted.dispatch( Boolean( json_data ) );
			
			// NULL the loader
			loader = null;
		}
		
		/**
		 * @private
		 * Callback for when the delete request IO errors
		 * 
		 * @param event <code>IOErrorEvent.IO_ERROR</code> 
		 */	
		private function onDeleteIOError( event : IOErrorEvent ) : void
		{
			// Rmove event listeners
			var loader : URLLoader = event.target as URLLoader;
			loader.removeEventListener( IOErrorEvent.IO_ERROR, onDeleteIOError );
			loader.removeEventListener( Event.COMPLETE, onDeleteComplete );
			
			errored.dispatch( event.text );
			
			// NULL the loader
			loader = null;
		}
	}
}