import java.util.ArrayList;
import java.util.HashMap;
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
import aima.core.probability.proposition.AssignmentProposition;
import utils.Graph;

public class IrrelevantEdge {

    public static BayesianNetwork irrilevanteEdgeGraph(BayesianNetwork bn, AssignmentProposition[] ap) {

        HashMap<Node, RandomVariable> node_randv = new HashMap<>();
        HashMap<Node, double[]> nodeCPT = new HashMap<>();
        Graph<Node> newGraph = new Graph<>();

        List<RandomVariable> vars = bn.getVariablesInTopologicalOrder();

        // - creo una newGraph contenente gli stessi nodi e gli stessi archi della rete bayesiana.
        // - creo una mappa che associa ad ogni nodo, la cpt relativa alla rete bayesiana.
        for (RandomVariable r : vars) {
            Node nodeSource = bn.getNode(r);
            node_randv.put(nodeSource, r); //per ottenere la randomVariable corrispondente al nodo, che servir� per costruire la nuova rete bayesiana

            FiniteNode fn = (FiniteNode) nodeSource;
            double[] values = fn.getCPT().getFactorFor().getValues();
            nodeCPT.put(nodeSource, values);

            Set<Node> children = nodeSource.getChildren();
            Iterator childrenIterator = children.iterator();

            while (childrenIterator.hasNext()) {
                Node child = (Node) childrenIterator.next();
                newGraph.addEdge(nodeSource, child, false);

                nodeCPT.put(child, values);
            }
        }

        //rimuovo gli archi secondo il teorema
        for (int i = 0; i < ap.length; i++) {

            Node eviVar = bn.getNode(ap[i].getTermVariable());
            Set<Node> nodes = newGraph.vertexSet();
            for (Node n : nodes) {

                if (newGraph.hasEdge(eviVar, n)) {

                    newGraph.removeEdge(eviVar, n);
                    CPT cpt = (CPT) n.getCPD();
                    double[] values = cpt.getConditioningCase(ap[i]).getValues();
                    nodeCPT.put(n, values);

                }
            }
        }

        ArrayList<FiniteNode> rootsTemp = new ArrayList<>();
        Set<Node> nodeGraph = newGraph.vertexSet();

        //creo i nodi radice della nuova rete bayesiana, in funzione del newGrpah
        for (Node n : nodeGraph) {
            List<Node> parents = newGraph.get_parent(n);

            if (parents.size() < 1) {
                rootsTemp.add(new FullCPTNode(node_randv.get(n), nodeCPT.get(n)));
            }
        }

        FiniteNode[] roots = rootsTemp.toArray(new FiniteNode[rootsTemp.size()]);

        for (int i = 0; i < roots.length; i++) {
            createBN(roots[i], newGraph, nodeCPT, node_randv);
        }

        BayesianNetwork newBn = new BayesNet(roots);

        return newBn;
    }

    //metodo per creare una nuova rete bayesiana a partire dai nodi radice
    public static void createBN(FiniteNode root, Graph<Node> graph, HashMap<Node, double[]> nodeCPT, HashMap<Node, RandomVariable> node_randv) {

        List<Node> children = graph.get_children(root);

        for (Node child : children) {

            FiniteNode node = new FullCPTNode(node_randv.get(child), nodeCPT.get(child), root);
            System.out.println("finitenode : " + node + " root: " + root);

            if (graph.get_children(child).size() > 0) {
                createBN(node, graph, nodeCPT, node_randv);
            }

        }

    }
}
