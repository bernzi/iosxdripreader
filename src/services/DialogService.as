/**
 Copyright (C) 2016  Johan Degraeve
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/gpl.txt>.
 
 */
package services
{
	import com.distriqt.extension.dialog.Dialog;
	import com.distriqt.extension.dialog.DialogView;
	import com.distriqt.extension.dialog.events.DialogViewEvent;
	
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	
	import model.ModelLocator;

	/**
	 * Will process all dialogs - goal is that any other service that wants to interact with the user will use this service<br> 
	 * Reason for using this service is because some service may be generating requests to open dialogs, while a dialog is already open<br>
	 * This service is going to keep track if there's already a dialog open, in whcih case it's added to a queue.
	 * 
	 */
	public class DialogService
	{
		private static var _instance:DialogService = new DialogService();
		private static var initialStart:Boolean = true;
		private static var dialogViews:ArrayCollection;
		private static var dialogViewsMaxDurations:ArrayCollection;
		private static var dialogOpen:Boolean;
		private static var maxDurationTimer:Timer;
		
		public function DialogService()
		{
			if (_instance != null) {
				throw new Error("DialogService class  constructor can not be used");	
			}
		}
		
		public static function init(stage:Stage):void {
			if (!initialStart)
				return;
			else
				initialStart = false;
			
			Dialog.init(ModelLocator.resourceManagerInstance.getString('secrets','distriqt-key'));
			Dialog.service.root = stage;
			dialogViews = new ArrayCollection();
			dialogViewsMaxDurations = new ArrayCollection();
			dialogOpen = false;
		}
		
		/**
		 * if maxDurationInSeconds specified then the dialog will be closed after the specified time
		 */
		public static function addDialog(dialogView:DialogView, maxDurationInSeconds:Number = Number.NaN):void {
			if (dialogOpen) {
				dialogViews.addItem(dialogView);
				dialogViewsMaxDurations.addItem(maxDurationInSeconds);
				//dialog will be processed as soon as the dialog that is currently open is closed again
			} else {
				processNewDialog(dialogView, maxDurationInSeconds);
			}
		}
		
		private static function maxDurationReached(event:Event = null):void {
			if (dialogViews.length > 0) {
				(dialogViews.getItemAt(0) as DialogView).dispose();
				dialogOpen = false;
				if (dialogViews.length > 0) {
					var dialogViewToShow:DialogView = dialogViews.getItemAt(0) as DialogView;
					dialogViews.removeItemAt(0);
					dialogViewsMaxDurations.removeItemAt(0);
					processNewDialog(dialogViewToShow);
				}
			}
		}
		
		private static function processNewDialog(dialogView:DialogView, maxDurationInSeconds:Number = Number.NaN):void {
			dialogView.addEventListener(DialogViewEvent.CLOSED, dialogViewClosed);
			//dialogView.addEventListener(DialogViewEvent.CANCELLED, dialogViewClosed);
			dialogView.show();
			dialogOpen = true;
			if (!isNaN(maxDurationInSeconds)) {
				if (maxDurationInSeconds > 0) {
					disableMaxDurationTimer();
					maxDurationTimer = new Timer(maxDurationInSeconds * 1000, 1);
					maxDurationTimer.addEventListener(TimerEvent.TIMER, maxDurationReached);
					maxDurationTimer.start();
				}
			}
		}
		
		private static function dialogViewClosed(event:DialogViewEvent):void {
			disableMaxDurationTimer();
			
			var alert:DialogView = DialogView(event.currentTarget);
			alert.dispose();
			dialogOpen = false;
			if (dialogViews.length > 0) {
				var dialogViewToShow:DialogView = dialogViews.getItemAt(0) as DialogView;
				dialogViews.removeItemAt(0);
				var maxDuration:Number = dialogViewsMaxDurations.getItemAt(0) as Number;
				dialogViewsMaxDurations.removeItemAt(0);
				processNewDialog(dialogViewToShow, maxDuration);
			}
		}
		
		private static function disableMaxDurationTimer():void {
			if (maxDurationTimer != null) {
				if (maxDurationTimer.hasEventListener(TimerEvent.TIMER)) 
					maxDurationTimer.removeEventListener(TimerEvent.TIMER,maxDurationReached);
				maxDurationTimer.stop();
				maxDurationTimer = null;
			}
		}
	}
}