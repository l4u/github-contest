
import weka.classifiers.Classifier;
import weka.core.Instance;
import weka.core.Instances;
import java.io.*;

//
// Note to self: for (weka + this + Objc java bridge) to work: compile/run under Java 1.5 32-bit
//

// java docs: http://weka.sourceforge.net/doc/


public class Classification {
	
	private Classifier model;
	private Instances dataset;
	private final static int NUM_INDICATORS = 15;
	
	public Classification() {
		// load the model		
		try {
			//String modelName = "../data/J48_100.model";
			//String modelName = "../data/J48_500.model";
			//String modelName = "../data/decision_table_100.model";
			String modelName = "../data/bagging_100.model";
			
			// http://weka.wikispaces.com/Serialization
			ObjectInputStream ois = new ObjectInputStream(new FileInputStream(modelName));
			model = (Classifier) ois.readObject();
	 		ois.close();
			System.out.println(" > JAVA: Classifier loaded");
	
			Reader reader = new FileReader("../data/training_data_100.arff");
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
		double r1 = c.classify("0.00007,1,0,0.999939,0,0.000273,0.00045,0.002333,0.743662,0,0.949296,0,0.003597,0,0"); //0
		System.out.println("Successfully classified, got result: " + r1);
		double r2 = c.classify("0.000402,1,0,0.999939,0,0.00082,0.00045,0.007776,0.743662,0,0.949296,0,0.010791,0.002915,0.076923"); //1
		System.out.println("Successfully classified, got result: " + r2);
	}
}