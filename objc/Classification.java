
import weka.classifiers.Classifier;
import weka.core.Instance;
import weka.core.Instances;
import java.io.*;

//
// Note to self: for (weka + this + Objc java bridge) to work: compile/run under Java 1.5 32-bit
//

// java docs: http://weka.sourceforge.net/doc/


public class Classification {
	
	//
	// personalized classification model
	//
/*	
	public Classification() {
		
	}
	
	public double classify(String indicators) {
	}
*/	
	
	
	//
	// first attempt : global classification model
	//
	
	private Classifier model;
	private Instances dataset;
	/*private final static int NUM_INDICATORS = 15;*/
	private final static int NUM_INDICATORS = 10;
	
	public Classification() {
		// load the model		
		try {
			//String modelName = "../data/J48-100.model";
			//String modelName = "../data/J48-500.model";
			//String modelName = "../data/decision_table_100.model";
			String modelName = "../data/J48-100_2.model";
			
			// http://weka.wikispaces.com/Serialization
			ObjectInputStream ois = new ObjectInputStream(new FileInputStream(modelName));
			model = (Classifier) ois.readObject();
	 		ois.close();
			System.out.println(" > JAVA: Classifier loaded");
	
			//Reader reader = new FileReader("../data/training_data_100.arff");
			Reader reader = new FileReader("../data/training_data2_100.arff");
			dataset = new Instances(reader);
			reader.close();
			dataset.setClassIndex(dataset.numAttributes() - 1);
			System.out.println(" > JAVA: Dataset loaded");
			// delete all instances
			dataset.delete();
		} catch(Exception e){
			throw new RuntimeException("Could not load model: "+e.getMessage(), e);
		}
	}
	
	
	public double classify(String indicators) {
		// parse and validate
		String [] parts = indicators.split(",");
		if(parts.length!=NUM_INDICATORS) {
			throw new RuntimeException("Expected "+NUM_INDICATORS+" indicators, got: " + parts.length);
		}		
		// make an instance
		double [] values = new double[NUM_INDICATORS]; 
		for(int i=0; i<values.length; i++) {
			values[i] = Double.parseDouble(parts[i]);
		}				
		dataset.add(new Instance(1.0, values));
		
		// ask for a prediction
		double score = 99.99;
		try {
			//score = model.classifyInstance(dataset.instance(0));		
			
			double [] dist = model.distributionForInstance(dataset.instance(0));			
			score = dist[1];
		} catch(Exception e){
			throw new RuntimeException("Could not classify instance: " + e.getMessage(), e);
		}
		
		// remove
		dataset.delete();
		
		return score;
	}
	
	public static void main(String [] args) {
		Classification c = new Classification();
		double r1 = c.classify("0.985993,0.990659,0,0.823153,0.57191,0.159963,0.40585,0.410878,0,0"); //0
		System.out.println("Successfully classified, got result: " + r1);
		double r2 = c.classify("0.999065,0.998279,0,0.794534,0.97987,0.849634,0.045704,0.944698,0.904255,0.904255"); //1
		System.out.println("Successfully classified, got result: " + r2);
	}
	
}