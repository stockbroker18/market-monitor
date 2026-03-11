import { useQuery } from "@tanstack/react-query";
import axios from "axios";

export function usePrice(backendUrl: string, ticker: string, field: string) {
  return useQuery({
    queryKey: ["price", backendUrl, ticker, field],
    queryFn: async () => {
      const res = await axios.get(`${backendUrl}/api/data/reference`, {
        params: { ticker, field },
      });
      return res.data;
    },
    refetchInterval: 5000,
    enabled: !!ticker && !!field,
  });
}
