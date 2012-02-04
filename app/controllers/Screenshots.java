package controllers;

import java.io.InputStream;

import models.Screenshot;
import models.Test;
import play.mvc.Controller;

public class Screenshots extends Controller {

	public static void saveScreenshot(Screenshot screenshot) {
		screenshot.save();
		Test test = Test.findById(screenshot.testId);
		if (test != null) {
			if (!test.screenshots.contains(screenshot.id)) {
				test.screenshots.add(screenshot.id);
				test = test.merge();
				test.save();
			}
		}
		renderJSON(screenshot);
	} 
	
	public static void deleteScreenshot(Long testId, Long id) {
		Screenshot screenshot = Screenshot.findById(id);
		Test test = Test.findById(testId);
		if (screenshot != null && test != null) {
			screenshot.source.getFile().delete();
			screenshot.delete();
			test.screenshots.remove(id);
			test = test.merge();
			test.save();
			ok();
		} else {
			notFound();
		}
	}

	public static void loadScreenshot(Long testId, Long id) { 
		Screenshot screenshot = Screenshot.findById(id);
		if (screenshot != null) {
			response.setContentTypeIfNotSet(screenshot.source.type());
			InputStream binaryData = screenshot.source.get();
			renderBinary(binaryData);
		} else {
			notFound();
		}
	} 

	public static void getScreenshotName(long id) { 
		final Screenshot screenshot = Screenshot.findById(id); 
		renderText(screenshot.name);
	}
}