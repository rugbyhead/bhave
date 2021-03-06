package models.terms;

import java.util.LinkedList;
import java.util.List;
import javax.persistence.Entity;

import models.*;
import models.terms.BObject.BObjectType;
import play.db.jpa.Model;

@Entity
public abstract class BTerm extends JsonPersistingModel {
	
	public enum BTermType {
		Verb,
		Object,
		Subject,
		Conjunction,
		Article,
		Synonym;
	}

	public String name;
	public BTermType type;

	public BTerm(String name, BTermType type) {
		this.name = name;
		this.type = type;
	}
	
	public BTerm() {
		
	}
	
}
