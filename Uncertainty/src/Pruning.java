
import aima.core.probability.RandomVariable;
import aima.core.probability.bayes.BayesianNetwork;
import aima.core.probability.bayes.FiniteNode;
import aima.core.probability.bayes.Node;
import aima.core.probability.bayes.impl.BayesNet;
import aima.core.probability.bayes.impl.CPT;
import aima.core.probability.bayes.impl.FullCPTNode;
import aima.core.probability.example.BayesNetExampleFactory;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;
import java.util.Set;

/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 *
 * @author confo
 */
public class Pruning {
  
  
  public BayesianNetwork irrelevantNodeAncestor(BayesianNetwork bn,
                                                RandomVariable[] queryVars,
                                                RandomVariable[] evidenceVars){
    List<RandomVariable> topologicalOrder = bn.getVariablesInTopologicalOrder();
    List<RandomVariable> relevantRVs = irrelevantNodeAncestorHelpRV(bn, queryVars, evidenceVars);
    Collections.reverse(relevantRVs);
    List<FiniteNode> newNodes = new ArrayList<>();
    for(RandomVariable var : topologicalOrder){
        if(relevantRVs.contains(var)){
            Node node = bn.getNode(var);
            CPT cpt = (CPT) node.getCPD();
            Set<Node> parents = node.getParents();
            List<Node> newParents = new ArrayList<>();
            for(Node p : parents){  // I need to set as parents the new nodes, not the ones of the old bn
                for(Node np : newNodes){
                    if(p.equals(np)){
                        newParents.add(np);
                    }
                }
            }
            newNodes.add(new FullCPTNode(var, cpt.getProbabilityTable().getValues(), newParents.toArray(new Node[parents.size()])));
        }
    }
    List<Node> roots = new ArrayList<>();
    for(Node node : newNodes){
        System.out.println("Node: " + node.getRandomVariable().getName());
        System.out.println(node.getChildren());
        if(node.isRoot()){
            roots.add(node);
        }
    }
    
    return new BayesNet(roots.toArray(new Node[roots.size()]));
  }
  
  /*
    iterate through the random variables in inverse topological order;
    delete the variables in the last level if they are not query or evidence;
    at each subsequent level keep the new query and evidence variables found and
    all of those which still have at least one child (ancestors of relevant variables)
    @returns a list of the relevant random variables in inverse topological order
  */
  private List<RandomVariable> irrelevantNodeAncestorHelpRV(BayesianNetwork bn,
                                                            RandomVariable[] queryVars,
                                                            RandomVariable[] evidenceVars){
    List<RandomVariable> topologicalOrder = bn.getVariablesInTopologicalOrder();
    List<RandomVariable> varList = new ArrayList<>(topologicalOrder);
    Collections.reverse(varList);
    for (Iterator<RandomVariable> iterator = varList.iterator(); iterator.hasNext(); ) {
        RandomVariable var = iterator.next();
        boolean keep = false;
        for(int i = 0; i < queryVars.length; i++){
            if(var.getName().equals(queryVars[i].getName())){
                keep = true;
            }
        }
        for(int i = 0; i < evidenceVars.length; i++){
            if(var.getName().equals(evidenceVars[i].getName())){
                keep = true;
            }
        }
        for(Node child : bn.getNode(var).getChildren()){
            if(varList.contains(child.getRandomVariable())){
                keep = true;
            }
        }
        if(!keep){
            iterator.remove();
        }
    }
    return varList;
  }
  
  public static void main(String[] args){
      Pruning p = new Pruning();
      BayesianNetwork bn = BayesNetExampleFactory.constructBurglaryAlarmNetwork();
      //BayesianNetwork bn = BayesNetExampleFactory.constructCloudySprinklerRainWetGrassNetwork();
      List<RandomVariable> varList = bn.getVariablesInTopologicalOrder();
      RandomVariable[] queryVars = new RandomVariable[1];
      RandomVariable[] evidenceVars = new RandomVariable[1];
      for(RandomVariable rv : varList){
          if(rv.getName().equals("Earthquake")){
              queryVars[0] = rv;
          }
          if(rv.getName().equals("MaryCalls")){
              evidenceVars[0] = rv;
          }
      }
      BayesianNetwork newBN = p.irrelevantNodeAncestor(bn, queryVars, evidenceVars);
      System.out.println(newBN.getVariablesInTopologicalOrder());
      for(RandomVariable rv : newBN.getVariablesInTopologicalOrder()){
        System.out.println("Node: " + rv.getName());
        System.out.println(newBN.getNode(rv).getChildren());
      }
  }
}
