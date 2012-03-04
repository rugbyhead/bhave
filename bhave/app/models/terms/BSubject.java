package models.terms;

import javax.persistence.Entity;

@Entity
public class BSubject extends BTerm {

	public BSubject(String name) {
		super(name, BTermType.Subject);
	}

	@Override
	public BSubject createTestCopy() {
		return (BSubject) saveAsCopy(new BSubject(name));
	}
	
	

}
