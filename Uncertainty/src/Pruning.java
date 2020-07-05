
import aima.core.probability.RandomVariable;
import aima.core.probability.bayes.BayesianNetwork;
import aima.core.probability.bayes.FiniteNode;
import aima.core.probability.bayes.Node;
import aima.core.probability.bayes.impl.BayesNet;
import aima.core.probability.bayes.impl.CPT;
import aima.core.probability.bayes.impl.FullCPTNode;
import aima.core.probability.example.BayesNetExampleFactory;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;
import java.util.Set;
import utils.Graph;

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

    public BayesianNetwork theorem1(BayesianNetwork bn,
            RandomVariable[] queryVars,
            RandomVariable[] evidenceVars) {
        List<RandomVariable> topologicalOrder = bn.getVariablesInTopologicalOrder();
        List<RandomVariable> relevantRVs = theorem1Help(bn, queryVars, evidenceVars);
        Collections.reverse(relevantRVs);
        return newNetFromRandomVars(bn, topologicalOrder, relevantRVs);
    }
    
    /*
        creates a new Bayesian network where the relevant variables are newNetVars and the others are deleted.
        oldNetVars must be in topological order
    */
    private BayesNet newNetFromRandomVars(BayesianNetwork oldNet,
            List<RandomVariable> oldNetVars,
            List<RandomVariable> newNetVars){
        List<FiniteNode> newNodes = new ArrayList<>();
        for (RandomVariable var : oldNetVars) {
            if (newNetVars.contains(var)) {
                Node node = oldNet.getNode(var);
                Set<Node> parents = node.getParents();
                List<Node> newParents = new ArrayList<>();
                for (Node p : parents) {  // I need to set as parents the new nodes, not the ones of the old bn
                    for (Node np : newNodes) {
                        if (p.equals(np)) {
                            newParents.add(np);
                        }
                    }
                }
                double[] cptVal = { 0.5, 0.5 };
                if(parents.size() == newParents.size()){
                    FiniteNode fn = (FiniteNode) node;
                    cptVal = fn.getCPT().getFactorFor().getValues();
                }
                if(newParents.isEmpty()){
                    newNodes.add(new FullCPTNode(var, cptVal));
                } else{
                    newNodes.add(new FullCPTNode(var, cptVal, newParents.toArray(new Node[parents.size()])));
                }
            }
        }
        List<Node> roots = new ArrayList<>();
        for (Node node : newNodes) {
            if (node.isRoot()) {
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
    private List<RandomVariable> theorem1Help(BayesianNetwork bn,
            RandomVariable[] queryVars,
            RandomVariable[] evidenceVars) {
        List<RandomVariable> topologicalOrder = bn.getVariablesInTopologicalOrder();
        List<RandomVariable> varList = new ArrayList<>(topologicalOrder);
        Collections.reverse(varList);
        for (Iterator<RandomVariable> iterator = varList.iterator(); iterator.hasNext();) {
            RandomVariable var = iterator.next();
            boolean keep = false;
            for (int i = 0; i < queryVars.length; i++) {
                if (var.getName().equals(queryVars[i].getName())) {
                    keep = true;
                }
            }
            for (int i = 0; i < evidenceVars.length; i++) {
                if (var.getName().equals(evidenceVars[i].getName())) {
                    keep = true;
                }
            }
            for (Node child : bn.getNode(var).getChildren()) {
                if (varList.contains(child.getRandomVariable())) {
                    keep = true;
                }
            }
            if (!keep) {
                iterator.remove();
            }
        }
        return varList;
    }
    
    public BayesianNetwork theorem2(BayesianNetwork bn,
            RandomVariable[] queryVars,
            RandomVariable[] evidenceVars) {
        List<RandomVariable> topologicalOrder = bn.getVariablesInTopologicalOrder();
        List<RandomVariable> topologicalOrderCopy = new ArrayList<>(topologicalOrder);
        Graph moralGraph = moralGraph(bn);
        topologicalOrderCopy.removeAll(Arrays.asList(queryVars));
        topologicalOrderCopy.removeAll(Arrays.asList(evidenceVars));
        List<RandomVariable> relevantVars = new ArrayList<>();
        relevantVars.addAll(Arrays.asList(queryVars));
        relevantVars.addAll(Arrays.asList(evidenceVars));
        for(RandomVariable rvar : topologicalOrderCopy){
            Node end = bn.getNode(rvar);
            for(int i = 0; i < queryVars.length; ++i){
                Node start = bn.getNode(queryVars[i]);
                if(!relevantVars.contains(rvar) && !isMSeparated(moralGraph, start, end, evidenceVars)){
                    relevantVars.add(rvar);
                }
            }
        }
        return newNetFromRandomVars(bn, topologicalOrder, relevantVars);
    }

    public Graph moralGraph(BayesianNetwork bn) {
        Graph<Node> graph = new Graph<>();

        List<RandomVariable> variables = bn.getVariablesInTopologicalOrder();

        for (RandomVariable r : variables) {
            Node node = bn.getNode(r);
            graph.addVertex(node);
        }

        for (RandomVariable r : variables) {
            Node node = bn.getNode(r);
            Node[] parents = node.getParents().toArray(new Node[node.getParents().size()]);

            for (int i = 0; i < parents.length; i++) {
                graph.addEdge(parents[i], node, true);
                for (int j = i + 1; j < parents.length; j++) {
                    graph.addEdge(parents[i], parents[j], true);
                }
            }
        }
        return graph;
    }

    /*
    This method and its helper are not efficient but are easy to write and read
    */
    private boolean isMSeparated(Graph<Node> graph, Node start, Node end, RandomVariable[] eviVar) {
        return isMSeparatedHelp(graph.copy(), start, end, eviVar);
    }

    private boolean isMSeparatedHelp(Graph<Node> graph, Node start, Node end, RandomVariable[] eviVar) {
        boolean ret = true;
        for (RandomVariable r : eviVar) {
            String nameEvi = r.getName();
            String nameVar = start.getRandomVariable().getName();
            if (nameVar.contentEquals(nameEvi)) {
                return true;
            }
        }

        if (start.equals(end)) {
            return false;
        } else {
            List<Node> neighbors = graph.neighborsDestructive(start);
            if(neighbors != null){
                for (Node n : neighbors) {
                    ret = ret && isMSeparatedHelp(graph, n, end, eviVar);
                }
            }
        }
        return ret;
    }

    public static void main(String[] args) {
        Pruning p = new Pruning();
        BayesianNetwork bn = BayesNetExampleFactory.constructBurglaryAlarmNetwork();
        //BayesianNetwork bn = BayesNetExampleFactory.constructCloudySprinklerRainWetGrassNetwork();
        List<RandomVariable> varList = bn.getVariablesInTopologicalOrder();
        RandomVariable[] queryVars = new RandomVariable[1];
        RandomVariable[] evidenceVars = new RandomVariable[1];
        for (RandomVariable rv : varList) {
            if (rv.getName().equals("JohnCalls")) {
                queryVars[0] = rv;
            }
            if (rv.getName().equals("Alarm")) {
                evidenceVars[0] = rv;
            }
        }
        BayesianNetwork newBN = p.theorem1(bn, queryVars, evidenceVars);
        System.out.println(newBN.getVariablesInTopologicalOrder());
    }
}
