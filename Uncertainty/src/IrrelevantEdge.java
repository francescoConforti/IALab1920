package project;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Set;

import aima.core.probability.RandomVariable;
import aima.core.probability.bayes.BayesianNetwork;
import aima.core.probability.bayes.FiniteNode;
import aima.core.probability.bayes.Node;
import aima.core.probability.bayes.impl.BayesNet;
import aima.core.probability.bayes.impl.CPT;
import aima.core.probability.bayes.impl.FullCPTNode;
import aima.core.probability.example.BayesNetExampleFactory;
import aima.core.probability.proposition.AssignmentProposition;

public class IrrilevantEdge {
	
	public static BayesianNetwork irrilevantEdgeGraph (BayesianNetwork bn, AssignmentProposition[] ap) {
		
		HashMap<String, RandomVariable> rvsmap = new HashMap<String, RandomVariable>();
		HashMap<Node, RandomVariable> node_randv = new HashMap<Node, RandomVariable>();
		HashMap<Node, double[]> nodeCPT = new HashMap<Node, double[]>();
		List<Node> newNodes = new ArrayList<Node>();
		
		List<RandomVariable> vars = bn.getVariablesInTopologicalOrder();		
		
		// - creo una newGraph contenente gli stessi nodi e gli stessi archi della rete bayesiana.
		// - creo una mappa che associa ad ogni nodo, la cpt relativa alla rete bayesiana.
		for(RandomVariable r : vars) {
			Node nodeSource = bn.getNode(r);
			 
			node_randv.put(nodeSource, r); //per ottenere la randomVariable corrispondente al nodo, che servirà per costruire la nuova rete bayesiana
			
			CPT cpt = (CPT) nodeSource.getCPD();
			double[] values = cpt.getProbabilityTable().getValues();
			nodeCPT.put(nodeSource, values);
			
			if(eviContain(ap, nodeSource.getParents()).size() != 0) {
				cpt = (CPT) nodeSource.getCPD();
				values = cpt.getConditioningCase(ap).getValues();
				Set<Node> parent = copyParents(nodeSource.getParents(), newNodes);

				parent.removeAll(eviContain(ap, nodeSource.getParents()));
				FiniteNode[] parents = parent.toArray(new FiniteNode[parent.size()]);
				FiniteNode[] newParents = getnewParent(parents, newNodes);
				FiniteNode newNode = new FullCPTNode(r, values, newParents);
				System.out.println("new node  " + newNode.getParents());
				newNodes.add(newNode);
				
			} 
			
			else {
					
				cpt = (CPT) nodeSource.getCPD();
				values = cpt.getProbabilityTable().getValues();
				FiniteNode[] parent = nodeSource.getParents().toArray(new FiniteNode[nodeSource.getParents().size()]);
				FiniteNode[] newParents = getnewParent(parent, newNodes);
				FiniteNode newNode = new FullCPTNode(r, values, newParents);
				newNodes.add(newNode);
				
			}
		}
	
		ArrayList<FiniteNode> rootsTemp = new ArrayList<FiniteNode>();		
		List<Node> nodeGraph = newGraph.getNode();
		
		for(Node n : newNodes) {
			System.out.println(n);
			if(n.getParents().size() == 0) {
				rootsTemp.add((FiniteNode) n);
			}
		}
		
		System.out.println("test " + rootsTemp);
		FiniteNode[] roots = rootsTemp.toArray(new FiniteNode[rootsTemp.size()]);		
		
		BayesianNetwork newBn = new BayesNet(roots);
		
		
		List<RandomVariable> v = newBn.getVariablesInTopologicalOrder();
		
		for(RandomVariable r : v) {
			if(newBn.getNode(r).isRoot()) {
				System.out.println("radice" + r);
			}
		}
		
		return newBn;
	}
	
	public static Set<Node> copyParents(Set<Node> parent, List<Node> newNodes) {
		Set<Node> copyParents = new HashSet<Node>();
		
		Iterator<Node> parIterator = parent.iterator();
		while(parIterator.hasNext()) {
			Node node = parIterator.next();
			for(Node newNode : newNodes) {
				if(newNode.equals(node)) {
					copyParents.add(node);
				}
			}
			
		}
		
		return copyParents;
	}
	
	
	public static FiniteNode[] getnewParent(FiniteNode[] parents, List<Node> newNodes) {
		
		List<FiniteNode> newParentsTemp = new ArrayList<FiniteNode>();
		
		for(int i=0; i<parents.length; i++) {
			for(int j=i; j<newNodes.size(); j++) {
				if(parents[i].getRandomVariable().equals(newNodes.get(j).getRandomVariable())) {
					newParentsTemp.add((FiniteNode) newNodes.get(j));
				}
			}
		}
		
		FiniteNode[] newParents = newParentsTemp.toArray(new FiniteNode[newParentsTemp.size()]);
		
		return newParents;
	}
	
	
	public static Set<Node> eviContain(AssignmentProposition[] ap, Set<Node> nodes) {
		
		Set<Node> nodi = new HashSet<Node>();
		
		for (int i=0; i<ap.length; i++) {
			Iterator<Node> it = nodes.iterator();
			while(it.hasNext()) {
				Node parent = it.next();
				if(parent.getRandomVariable().equals(ap[i].getTermVariable())) {
					nodi.add(parent);
				}
			}
		}
		
		return nodi;
	}
	
	
	
	public static void main(String[] args) {
		BayesianNetwork bn= BayesNetExampleFactory.constructBurglaryAlarmNetwork();
		
		System.out.println(bn.getVariablesInTopologicalOrder());
		
		RandomVariable[] query = new RandomVariable[1];
		AssignmentProposition[] ap = new AssignmentProposition[1];
		
		query[0] = bn.getVariablesInTopologicalOrder().get(0);
		ap[0] = new AssignmentProposition(bn.getVariablesInTopologicalOrder().get(2), true);
		
		BayesianNetwork ok = irrilevantEdgeGraph(bn, ap);
	}
}
